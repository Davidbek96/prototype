// gemini_chat_model.dart
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

    // retry/backoff config
    int attempt429 = 0;
    const int max429Retries = 3;

    // gap/keep-alive config
    int gapRetry = 0;
    const int maxGapRetries = 2; // number of times to retry on token gap
    const Duration initialTimeout = Duration(seconds: 20);
    const Duration gapTimeout = Duration(seconds: 5);

    // start/stop helper (will create new HTTP request each attempt)
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
          // Rate limit — retry with exponential backoff
          if (attempt429 < max429Retries) {
            final wait = Duration(seconds: 2 << attempt429);
            attempt429++;
            print("⚠️ 429 received, retry #$attempt429 in ${wait.inSeconds}s");
            await Future.delayed(wait);
            return startRequest();
          } else {
            controller.addError("Rate limit (429). Retries exhausted.");
            await controller.close();
            return;
          }
        }

        if (response.statusCode != 200) {
          controller.addError("Gemini API error: ${response.statusCode}");
          await controller.close();
          return;
        }

        // initial response watchdog
        bool firstTokenSeen = false;
        initialTimer = Timer(initialTimeout, () {
          if (!firstTokenSeen && !controller.isClosed) {
            controller.addError(
              "Timeout: no response within ${initialTimeout.inSeconds}s",
            );
            // cancel the stream
            sub?.cancel();
            try {
              controller.close();
            } catch (_) {}
          }
        });

        // Decode raw bytes (DO NOT line-split — Gemini can send arrays across chunks)
        final decodedStream = response.stream.transform(const Utf8Decoder());

        sub = decodedStream.listen(
          (chunk) {
            if (cancelled) {
              sub?.cancel();
              return;
            }

            // reset 429 attempt counter on progress
            attempt429 = 0;

            // append raw chunk (keep whitespace; brace matcher will handle)
            buffer += chunk;
            // extract any complete JSON objects from buffer using brace matching
            while (true) {
              final startIdx = buffer.indexOf('{');
              if (startIdx == -1) {
                // nothing to parse yet. trim buffer to avoid unbounded growth
                if (buffer.length > 4096)
                  buffer = buffer.substring(buffer.length - 2048);
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
                // no full object yet — keep waiting
                // if startIdx > 0, drop leading noise
                if (startIdx > 0) buffer = buffer.substring(startIdx);
                break;
              }

              // We have a complete JSON object
              final jsonStr = buffer.substring(startIdx, endIdx + 1);
              // Advance buffer past the object (also drop following commas/spaces)
              buffer = buffer.substring(endIdx + 1);

              // parse it
              try {
                final jsonData = jsonDecode(jsonStr);
                // If we got a token, cancel initial timer
                if (!firstTokenSeen) {
                  firstTokenSeen = true;
                  initialTimer?.cancel();
                }

                // reset gap timer on any object processed
                gapTimer?.cancel();
                gapTimer = Timer(gapTimeout, () async {
                  // gap detected
                  gapRetry++;
                  print(
                    "⚠️ Gap of ${gapTimeout.inSeconds}s detected (attempt $gapRetry/$maxGapRetries).",
                  );
                  sub?.cancel();
                  if (gapRetry <= maxGapRetries && !cancelled) {
                    // short backoff, then retry the whole request
                    final wait = Duration(seconds: 1 + gapRetry);
                    await Future.delayed(wait);
                    if (!cancelled) await startRequest();
                  } else {
                    if (!controller.isClosed) {
                      controller.addError(
                        "Stream stalled (no tokens for ${gapTimeout.inSeconds}s).",
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
                        // Emit token (could be a phrase chunk)
                        if (!controller.isClosed) {
                          controller.add(ChatChunk(delta: text.toString()));
                        }
                      }
                    }
                  }

                  // finish reason (if any)
                  final finishReason = candidate["finishReason"];
                  if (finishReason != null &&
                      finishReason.toString().toUpperCase() == "STOP") {
                    if (!controller.isClosed) {
                      controller.add(ChatChunk(isFinal: true));
                      controller.close();
                    }
                  }
                }
              } catch (e) {
                print("❌ JSON parse error: $e -- raw=$jsonStr");
                // continue processing buffer
              }
            } // while extract objects
          },
          onDone: () {
            gapTimer?.cancel();
            initialTimer?.cancel();
            if (!controller.isClosed) {
              controller.add(ChatChunk(isFinal: true));
              controller.close();
            }
          },
          onError: (err) {
            initialTimer?.cancel();
            gapTimer?.cancel();
            if (!controller.isClosed) controller.addError(err);
          },
          cancelOnError: true,
        );
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError("Request failed: $e");
          // The outer retry/backoff: if transient, caller can retry by re-calling streamReply.
          // Here we will rethrow by closing controller after short delay
          try {
            await Future.delayed(const Duration(milliseconds: 200));
            controller.close();
          } catch (_) {}
        }
      }
    } // end startRequest

    // Start streaming in background
    unawaited(startRequest());

    // when controller is cancelled by listener, set cancelled = true
    controller.onCancel = () {
      cancelled = true;
      // nothing else to do; HTTP subscriptions will see cancelled flag and stop
    };

    return controller.stream;
  }
}

// small helper to allow calling async without await in dart < 3
void unawaited(Future<void> f) {}
