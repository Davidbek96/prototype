# Webview & Chatbot Prototype
A production-oriented Flutter prototype: a **WebView ↔ Native Hook** demo + **AI voice chatbot** (Gemini/OpenAI compatible), built with **GetX** and modular architecture. The README incorporates the project's design brief and core requirements (WebView hooks, streaming LLM responses, STT/TTS flow, permissions, and error handling).

> **Important:** The chatbot requires a valid **Gemini API Key** registered in the app (Settings → API Key) to function.

---

## 🚩 Summary / What this project is
This repository is a prototype that demonstrates:
- Native ↔ WebView bi-directional communication (JS ↔ Native hooks).
- Real-time voice-driven AI chat: STT (partial transcription) → streaming LLM (partial-token rendering) → TTS (per-bubble playback), with seamless, cancellable streams.
- App-level features: settings (API key, voice/lang), connectivity handling, WebView bridge, and demo assets (local HTML in assets).

The original project brief and technical spec were used to extract requirements and main features. fileciteturn0file0

---

## 📂 Project layout (key files)
```
lib/
 ├── bindings/               # GetX dependency bindings (chat_binding.dart)
 ├── controllers/            # GetX controllers (chat_controller, settings_controller, webview_controller)
 ├── domain/                 # Streaming/chat domain logic (chat_stream_manager, transient_message_service)
 ├── models/                 # Chat + Gemini/OpenAI models (chat_model.dart, gemini_chat_model.dart)
 ├── pages/                  # Screens (chat_page, help_docs_page, home_page, settings_page, webview_page)
 ├── services/               # Connectivity, Gemini manager, permissions, STT/TTS services
 ├── utils/                  # Utilities (webview_bridge)
 ├── widgets/                # Reusable widgets (chat UI, settings cards)
 └── main.dart               # App entry point
assets/
 └── demo/index.html         # Demo web page loaded into WebView
```

---

## ✨ Main features (added from spec)

### 1) WebView ↔ Native Hook (JS ↔ Native)
- Supports bidirectional JSON messaging: `window.JOI.postMessage(json)` (JS → Native) and `window.JOI.onMessage(json)` (Native → JS).  
- Message schema (request / response / event / error) is enforced and the web demo times out requests after 10 seconds if no response.  
- Example native actions exposed: `vibrate`, `getDeviceInfo`, `pickImage`, `copyToClipboard`, custom actions.  
- Native can push events (battery/network ticks, timers) to the WebView for real-time UI updates.

### 2) Streaming AI Chat (STT → LLM stream → TTS)
- **STT**: Hold-to-talk mic (partial transcription events are shown live). Uses on-device speech APIs (Android/iOS) to provide partial transcripts.
- **LLM streaming**: Abstract `ChatModel` interface allows swapping backends (OpenAI, Gemini, or a mock). Streams tokens as `ChatChunk` and supports mid-stream cancellation and retry. The UI renders tokens incrementally (typewriter-style).
- **TTS**: Per-bubble playback; option to auto-play when model response finishes; supports replay of any bubble's TTS output.
- Robust UX for cancel/stop/retry during streaming and speech playback.

### 3) Reliability & Timeouts
- LLM response timeout and token gap handling: if no response within configured limits, keep-alive or retry logic triggers (spec suggests 20s response wait, 5s token gap threshold).
- WebView requests time out after 10s (E_TIMEOUT) and return structured errors to JS side.

### 4) Permissions & Error Handling
- Microphone permissions are requested at runtime; clear user messages are shown for:
  - Microphone permission denied or missing STT engine.
  - Network errors or no connectivity.
  - Missing/invalid API key (direct user to Settings).
- Apps must include platform permission keys: `RECORD_AUDIO` (Android), `NSMicrophoneUsageDescription` / `NSSpeechRecognitionUsageDescription` (iOS).

### 5) Adapter & Architecture
- `ChatModel` adapter pattern to decouple UI from LLM provider: any model implementing a `streamReply(...) -> Stream<ChatChunk>` can be used. This enables swapping Gemini/OpenAI without changing UI logic.
- Separation of concerns: controllers (GetX) for state, services for external APIs, domain layer for streaming/chat logic.

---

## 📥 Setup & Run

1. Clone repository
```bash
git clone https://github.com/your-username/flutter-gemini-chatbot.git
cd flutter-gemini-chatbot
```

2. Install dependencies
```bash
flutter pub get
```

3. Register Gemini API Key (required)
- Recommended: Open the app → **Settings → API Key** and paste your Gemini API key.  
- **Do not** hardcode keys for production. For quick testing you may temporarily place it in `lib/models/gemini_chat_model.dart` (search for `apiKey`).

4. Run
```bash
flutter run
```

---

## 🧪 Testing & Demo flows
- WebView demo: open the WebView screen and interact with the demo page; trigger native actions (vibrate, clipboard, pick image) to see JS↔Native messaging.
- Voice chat demo: open Chat screen, press-and-hold mic to speak (partial STT will appear), release to send to model. Model tokens should stream into the chat bubble and optionally play via TTS after finishing.
- Settings: configure language, voice, API key, and toggle auto-play TTS.

---

## ⚙️ Config & Environment
- Provide `.env.example` for any environment variables (API endpoints, keys). If using platform-specific keys/certificates, document them in the repo.
- Ensure app has following platform permissions configured:
  - Android: `android.permission.RECORD_AUDIO`
  - iOS: `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`

---

## 🛠 Troubleshooting
- If streaming stalls: check network + API key validity. Restart chat stream or press retry.  
- If STT doesn't start: confirm microphone permission and presence of an STT engine. On Android test with Google Speech services.  
- Reset local storage: open Settings → Danger utilities → Reset (or programmatically `GetStorage().erase()`).
- If WebView messages time out, inspect the demo HTML (`assets/demo/index.html`) to see requestIds and payloads.

---

## 🤝 Contributing
Contributions welcome — issues, PRs, and feedback. Suggested improvements:
- Add unit/integration tests for stream manager and WebView bridge.  
- Add PDF/export of conversation history.  
- Add remote settings / feature flags for LLM backend selection.

---

## 📜 License
MIT License — see `LICENSE`

---

## 👤 Contact
DovudjonUsmonov@gmail.com
