import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/chat_model.dart';

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
    final controller = StreamController<ChatChunk>();
    bool cancelled = false;
    int tokenCounter = 0;

    // retry/backoff config
    int attempt429 = 0;
    const int max429Retries = 3;

    // gap/keep-alive config
    int gapRetry = 0;
    const int maxGapRetries = 2;
    const Duration initialTimeout = Duration(seconds: 20);
    const Duration gapTimeout = Duration(seconds: 5);

    Future<void> startRequest() async {
      if (cancelled) return;
      Timer? initialTimer;
      Timer? gapTimer;
      StreamSubscription? sub;
      String buffer = "";

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

        final response = await request.send();

        if (cancelled) {
          try {
            await response.stream.drain();
          } catch (_) {}
          return;
        }

        if (response.statusCode == 429) {
          if (attempt429 < max429Retries) {
            final wait = Duration(seconds: 2 << attempt429);
            attempt429++;
            controller.add(
              ChatChunk(
                delta: "",
                meta: {
                  "event": "retry",
                  "reason": "rate_limit",
                  "attempt": attempt429,
                  "waitSeconds": wait.inSeconds,
                },
              ),
            );
            await Future.delayed(wait);
            return startRequest();
          } else {
            controller.add(
              ChatChunk(
                delta: "",
                isFinal: true,
                meta: {"error": "Rate limit (429). Retries exhausted."},
              ),
            );
            await controller.close();
            return;
          }
        }

        if (response.statusCode != 200) {
          controller.add(
            ChatChunk(
              delta: "",
              isFinal: true,
              meta: {"error": "Gemini API error: ${response.statusCode}"},
            ),
          );
          await controller.close();
          return;
        }

        bool firstTokenSeen = false;
        initialTimer = Timer(initialTimeout, () {
          if (!firstTokenSeen && !controller.isClosed) {
            controller.add(
              ChatChunk(
                delta: "",
                isFinal: true,
                meta: {
                  "error":
                      "Timeout: no response in ${initialTimeout.inSeconds}s",
                },
              ),
            );
            sub?.cancel();
            try {
              controller.close();
            } catch (_) {}
          }
        });

        final decodedStream = response.stream.transform(const Utf8Decoder());

        sub = decodedStream.listen(
          (chunk) {
            if (cancelled) {
              sub?.cancel();
              return;
            }

            attempt429 = 0;
            buffer += chunk;

            while (true) {
              final startIdx = buffer.indexOf('{');
              if (startIdx == -1) {
                if (buffer.length > 4096) {
                  buffer = buffer.substring(buffer.length - 2048);
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
                  initialTimer?.cancel();
                }

                gapTimer?.cancel();
                gapTimer = Timer(gapTimeout, () async {
                  gapRetry++;
                  controller.add(
                    ChatChunk(
                      delta: "",
                      meta: {
                        "event": "gap_retry",
                        "attempt": gapRetry,
                        "timeoutSeconds": gapTimeout.inSeconds,
                      },
                    ),
                  );
                  sub?.cancel();
                  if (gapRetry <= maxGapRetries && !cancelled) {
                    final wait = Duration(seconds: 1 + gapRetry);
                    await Future.delayed(wait);
                    if (!cancelled) await startRequest();
                  } else {
                    if (!controller.isClosed) {
                      controller.add(
                        ChatChunk(
                          delta: "",
                          isFinal: true,
                          meta: {
                            "error":
                                "Stream stalled (no tokens for ${gapTimeout.inSeconds}s).",
                          },
                        ),
                      );
                      try {
                        controller.close();
                      } catch (_) {}
                    }
                  }
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
                        if (!controller.isClosed) {
                          controller.add(
                            ChatChunk(
                              delta: text.toString(),
                              meta: {
                                "model": model,
                                "tokenCount": tokenCounter,
                              },
                            ),
                          );
                        }
                      }
                    }
                  }

                  final finishReason = candidate["finishReason"];
                  if (finishReason != null &&
                      finishReason.toString().toUpperCase() == "STOP") {
                    if (!controller.isClosed) {
                      controller.add(
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
                      controller.close();
                    }
                  }
                }
              } catch (_) {
                // skip parse errors, keep buffer
              }
            }
          },
          onDone: () {
            gapTimer?.cancel();
            initialTimer?.cancel();
            if (!controller.isClosed) {
              controller.add(
                ChatChunk(
                  delta: "",
                  isFinal: true,
                  meta: {"event": "done", "tokenCount": tokenCounter},
                ),
              );
              controller.close();
            }
          },
          onError: (err) {
            initialTimer?.cancel();
            gapTimer?.cancel();
            if (!controller.isClosed) {
              controller.add(
                ChatChunk(
                  delta: "",
                  isFinal: true,
                  meta: {"error": err.toString()},
                ),
              );
            }
          },
          cancelOnError: true,
        );
      } catch (e) {
        if (!controller.isClosed) {
          controller.add(
            ChatChunk(
              delta: "",
              isFinal: true,
              meta: {"error": "Request failed: $e"},
            ),
          );
          try {
            await Future.delayed(const Duration(milliseconds: 200));
            controller.close();
          } catch (_) {}
        }
      }
    }

    unawaited(startRequest());

    controller.onCancel = () {
      cancelled = true;
    };

    return controller.stream;
  }
}

// small helper for dart < 3
void unawaited(Future<void> f) {}
