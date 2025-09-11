import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/chat_model.dart';

/// Robust Gemini streaming adapter: guards against adding events after the
/// stream controller is closed and cleans up timers/subscriptions on cancel.
class GeminiChatModel implements ChatModel {
  final String apiKey;
  final String model;

  GeminiChatModel({required this.apiKey, this.model = "gemini-2.0-flash"});

  @override
  Stream<ChatChunk> streamReply({
    required List<ChatMessage> messages,
    double? temperature,
    Map<String, dynamic>? options,
  }) {
    // Shared state visible to onCancel
    Timer? initialTimer;
    Timer? gapTimer;
    StreamSubscription? sub;
    http.StreamedResponse? response;
    bool cancelled = false;
    int tokenCounter = 0;

    // Create controller with onCancel so we can clean up when listener cancels
    late final StreamController<ChatChunk> controller;
    controller = StreamController<ChatChunk>(
      onCancel: () async {
        cancelled = true;
        try {
          await sub?.cancel();
        } catch (_) {}
        try {
          initialTimer?.cancel();
        } catch (_) {}
        try {
          gapTimer?.cancel();
        } catch (_) {}
        try {
          await response?.stream.drain();
        } catch (_) {}
      },
    );

    // Helper to add safely to the stream
    void safeAdd(ChatChunk chunk) {
      if (cancelled || controller.isClosed) return;
      try {
        controller.add(chunk);
      } catch (e, st) {
        // defensive: if add still throws, swallow and log
        // ignore: avoid_print
        print('GeminiChatModel.safeAdd error: $e\n$st');
      }
    }

    // main request logic (extracted so we can restart on gap/retry)
    Future<void> startRequest() async {
      if (cancelled || controller.isClosed) return;

      // cancel previous timers/sub if any
      try {
        initialTimer?.cancel();
      } catch (_) {}
      try {
        gapTimer?.cancel();
      } catch (_) {}
      try {
        await sub?.cancel();
      } catch (_) {}
      response = null;
      String buffer = "";
      bool firstTokenSeen = false;

      try {
        final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent",
        );

        final headers = {
          "Content-Type": "application/json",
          "X-goog-api-key": apiKey,
        };

        final body = {
          "contents": messages
              .map(
                (m) => {
                  "role": m.role,
                  "parts": [
                    {"text": m.content},
                  ],
                },
              )
              .toList(),
          "generationConfig": {"temperature": temperature ?? 0.7},
        };

        final request = http.Request("POST", url)
          ..headers.addAll(headers)
          ..body = jsonEncode(body);

        response = await request.send();

        if (cancelled || controller.isClosed) {
          try {
            await response?.stream.drain();
          } catch (_) {}
          return;
        }

        // At this point response is non-null. Promote to a local non-nullable var.
        final resp = response!;

        // handle 429 as a chunk with retry metadata (or treat as error after retries)
        if (resp.statusCode == 429) {
          safeAdd(
            ChatChunk(
              delta: "",
              meta: {"event": "error", "error": "Rate limit (429)"},
            ),
          );
          try {
            if (!controller.isClosed) await controller.close();
          } catch (_) {}
          return;
        }

        if (resp.statusCode != 200) {
          safeAdd(
            ChatChunk(
              delta: "",
              isFinal: true,
              meta: {"error": "Gemini API error: ${resp.statusCode}"},
            ),
          );
          try {
            if (!controller.isClosed) await controller.close();
          } catch (_) {}
          return;
        }

        // initial-response watchdog (20s)
        initialTimer = Timer(const Duration(seconds: 20), () {
          if (cancelled || controller.isClosed) return;
          if (!firstTokenSeen) {
            safeAdd(
              ChatChunk(
                delta: "",
                isFinal: true,
                meta: {"error": "Timeout: no response in 20s"},
              ),
            );
            try {
              sub?.cancel();
            } catch (_) {}
            try {
              if (!controller.isClosed) controller.close();
            } catch (_) {}
          }
        });

        final decoded = resp.stream.transform(const Utf8Decoder());

        sub = decoded.listen(
          (chunk) {
            if (cancelled || controller.isClosed) {
              try {
                sub?.cancel();
              } catch (_) {}
              return;
            }

            buffer += chunk;

            while (true) {
              final startIdx = buffer.indexOf('{');
              if (startIdx == -1) {
                if (buffer.length > 8192) {
                  buffer = buffer.substring(buffer.length - 4096);
                }
                break;
              }

              int brace = 0;
              int endIdx = -1;
              for (int i = startIdx; i < buffer.length; i++) {
                final code = buffer.codeUnitAt(i);
                if (code == 123) brace++; // '{'
                if (code == 125) {
                  brace--;
                  if (brace == 0) {
                    endIdx = i;
                    break;
                  }
                }
              }

              if (endIdx == -1) {
                if (startIdx > 0) buffer = buffer.substring(startIdx);
                break;
              }

              final jsonStr = buffer.substring(startIdx, endIdx + 1);
              buffer = buffer.substring(endIdx + 1);

              try {
                final jsonData = jsonDecode(jsonStr);

                if (!firstTokenSeen) {
                  firstTokenSeen = true;
                  try {
                    initialTimer?.cancel();
                  } catch (_) {}
                }

                try {
                  gapTimer?.cancel();
                } catch (_) {}

                // set gap timer (5s)
                gapTimer = Timer(const Duration(seconds: 5), () async {
                  if (cancelled || controller.isClosed) return;
                  // emit a small meta chunk indicating a gap/retry intention
                  safeAdd(
                    ChatChunk(
                      delta: "",
                      meta: {"event": "gap_retry", "timeoutSeconds": 5},
                    ),
                  );

                  try {
                    await sub?.cancel();
                  } catch (_) {}

                  if (cancelled || controller.isClosed) return;
                  // backoff then restart
                  await Future.delayed(const Duration(seconds: 1));
                  if (cancelled || controller.isClosed) return;
                  await startRequest();
                });

                final candidates = jsonData["candidates"];
                if (candidates != null &&
                    candidates is List &&
                    candidates.isNotEmpty) {
                  final candidate = candidates[0];
                  final parts = candidate["content"]?["parts"];
                  if (parts != null && parts is List && parts.isNotEmpty) {
                    for (final part in parts) {
                      final text = part["text"];
                      if (text != null && text.toString().isNotEmpty) {
                        tokenCounter++;
                        safeAdd(
                          ChatChunk(
                            delta: text.toString(),
                            meta: {"model": model, "tokenCount": tokenCounter},
                          ),
                        );
                      }
                    }
                  }

                  final finishReason = candidate["finishReason"];
                  if (finishReason != null &&
                      finishReason.toString().toUpperCase() == "STOP") {
                    safeAdd(
                      ChatChunk(
                        delta: "",
                        isFinal: true,
                        meta: {
                          "event": "finish",
                          "reason": finishReason,
                          "tokenCount": tokenCounter,
                        },
                      ),
                    );
                    try {
                      if (!controller.isClosed) controller.close();
                    } catch (_) {}
                  }
                }
              } catch (e, st) {
                // parse error: keep buffer, continue. Log for debugging.
                // ignore: avoid_print
                print('Gemini parse error: $e\n$st\njsonStr=$jsonStr');
              }
            } // while
          }, // onData
          onDone: () {
            try {
              gapTimer?.cancel();
            } catch (_) {}
            try {
              initialTimer?.cancel();
            } catch (_) {}
            if (!controller.isClosed) {
              safeAdd(
                ChatChunk(
                  delta: "",
                  isFinal: true,
                  meta: {"event": "done", "tokenCount": tokenCounter},
                ),
              );
              try {
                controller.close();
              } catch (_) {}
            }
          },
          onError: (err) {
            try {
              initialTimer?.cancel();
            } catch (_) {}
            try {
              gapTimer?.cancel();
            } catch (_) {}
            if (!controller.isClosed) {
              safeAdd(
                ChatChunk(
                  delta: "",
                  isFinal: true,
                  meta: {"error": err.toString()},
                ),
              );
              try {
                controller.close();
              } catch (_) {}
            }
          },
          cancelOnError: true,
        );
      } catch (e, st) {
        if (!controller.isClosed) {
          safeAdd(
            ChatChunk(
              delta: "",
              isFinal: true,
              meta: {"error": "Request failed: $e"},
            ),
          );
          try {
            // short delay before close to let UI process chunk if necessary
            Future.delayed(
              const Duration(milliseconds: 100),
            ).then((_) => controller.close()).catchError((_) {});
          } catch (_) {}
        }
        // debug print
        // ignore: avoid_print
        print('Gemini startRequest exception: $e\n$st');
      }
    } // end startRequest

    // start the first request but do not await it
    unawaited(startRequest());

    return controller.stream;
  }
}

// small helper (no-op) to mimic unawaited pattern
void unawaited(Future<void> f) {}
