# 🌐 Webview & Chatbot Prototype  
_WebView ↔ 네이티브 통신과 Gemini 기반 AI 음성 챗봇을 결합한 Flutter 프로토타입_

---

## 📖 도움말 & 문서 (Korean)

**Webview & Chatbot Prototype**에 오신 것을 환영합니다!  
이 문서는 주요 기능, 시작 방법, 문제 해결 및 기술 사양을 안내합니다.

---

### ✨ 주요 기능
- 🤖 **Gemini AI 챗봇** – 실시간 스트리밍 대화
- 🎙 **음성 입력 (STT)** – 마이크 버튼을 길게 눌러 말하기
- 🔊 **TTS (텍스트 읽기)** – 챗봇 응답을 음성으로 출력
- 🌐 **WebView ↔ Native Hook** – 양방향 메시지 교환 (JS ↔ Native)
- ⚙️ **설정 페이지** – API 키, 언어, 음성 옵션 관리
- 📖 **도움말 & 문서 페이지** – 사용자 가이드 내장

---

### 🚀 시작하기 & API 키
1. **처음 설치 시** 앱은 `.env` 파일의 기본 API 키를 불러옵니다.  
2. API 키는 언제든 **설정 → API 키**에서 교체/삭제할 수 있습니다.  
   - 삭제 시 새 키를 저장하기 전까지 챗봇은 작동하지 않습니다.  
3. 유효한 키 저장 후 **채팅 페이지**에서 대화를 시작하세요.  
4. 🎤 마이크 버튼을 **길게 누른 상태로 말하기**  
5. **설정**에서 자동 TTS를 켜면 응답이 자동으로 읽어집니다.

---

### 🐛 문제 해결
- **유효하지 않은 API 키** → 설정에서 키 확인  
- **챗봇 응답 없음** → 네트워크 연결 확인  
- **음성 입력 안 됨** → 기기 마이크 권한 확인  
- **TTS 작동 안 함** → 기기에 TTS 엔진 설치 여부 확인  

---

### ℹ️ 기술 스택
- **GetX** → 상태 관리  
- **GetStorage** → 로컬 저장소  
- **Dotenv** → 환경 변수  
- **Gemini API** → AI 챗봇  
- **speech_to_text** → 음성 입력  
- **flutter_tts** → 음성 출력  
- **connectivity_plus** → 네트워크 모니터링  
- **permission_handler** → 권한 관리  

---

### 📂 프로젝트 구조
lib
├── features                        // Feature-based modular architecture
│   ├── chat                        // 💬 Chat module (AI chatbot core)
│   │   ├── domain                  // Business logic (independent of UI)
│   │   │   └── chat_stream_manager.dart   // Manages streaming chat responses
│   │   ├── models                  // Data models & adapters
│   │   │   ├── chat_model.dart          // Base chat model interface
│   │   │   ├── gemini_adapter.dart      // Adapter to connect with Gemini API
│   │   │   └── gemini_manager.dart      // Manager for Gemini sessions
│   │   ├── services                // External integrations & utilities
│   │   │   ├── stt_service.dart         // Speech-to-Text service (voice input)
│   │   │   ├── transient_message_service.dart // Handles temporary chat messages
│   │   │   └── tts_service.dart         // Text-to-Speech service (voice output)
│   │   ├── widgets                 // UI components for chat
│   │   │   ├── action_card.dart         // Card with actions (buttons/shortcuts)
│   │   │   ├── chat_bubble.dart         // UI for chat messages
│   │   │   ├── input_area.dart          // Chat input field (text + mic)
│   │   │   ├── mic_pulse_btn.dart       // Animated mic button for voice input
│   │   │   └── show_list_empty.dart     // Empty state widget (no chats)
│   │   ├── chat_binding.dart        // GetX binding (dependency injection)
│   │   ├── chat_controller.dart     // GetX controller (state management)
│   │   └── chat_page.dart           // Main chat screen UI
│   │
│   ├── help_docs                    // 📖 Help & documentation module
│   │   └── help_docs_page.dart          // In-app help & docs screen
│   │
│   ├── home                         // 🏠 Home module
│   │   └── home_page.dart               // App entry/home page
│   │
│   ├── settings                     // ⚙️ Settings module
│   │   ├── widgets                  // UI widgets for settings
│   │   │   ├── api_key_card.dart        // API key input card
│   │   │   ├── danger_utilities_card.dart // Utilities (reset, clear storage)
│   │   │   ├── voice_language_card.dart  // Language & voice options
│   │   │   └── settings_controller.dart // GetX controller for settings
│   │   └── settings_page.dart           // Settings screen UI
│   │
│   └── webview                      // 🌐 WebView integration module
│       ├── bridge                   // Web ↔ Native bridge layer
│       │   ├── bridge_controller.dart    // Handles WebView <-> Native messages
│       │   └── messages_model.dart       // Data model for WebView messages
│       └── webview_page.dart             // WebView screen UI
│
├── shared                           // Shared resources across features
│   ├── services                     // Common/global services
│   └── translations                 // i18n translations
│
├── app.dart                         // Root app configuration (routes, themes)
└── main.dart                        // App entry point (main function)


### 🙏 마무리
**Webview & Chatbot Prototype**을 사용해 주셔서 감사합니다.  
여러분의 피드백과 제안은 앱의 발전에 큰 도움이 됩니다! 🚀

---

---

## 📘 Help & Documentation (English)

Welcome to **Webview & Chatbot Prototype**!  
This document explains the main features, setup, troubleshooting, and technical specifications.

---

### ✨ Main Features
- 🤖 **Gemini AI Chatbot** – Real-time streaming responses
- 🎙 **Voice Input (STT)** – Hold mic button to speak
- 🔊 **TTS (Text-to-Speech)** – Chatbot reads responses aloud
- 🌐 **WebView ↔ Native Hook** – Bidirectional JSON messaging
- ⚙️ **Settings Page** – Manage API key, language, and voice options
- 📖 **Help & Docs Page** – In-app guide

---

### 🚀 Getting Started & API Key
1. On first install, the app loads an API key from `.env`.  
2. API key can be updated anytime in **Settings → API Key**.  
   - If deleted, chatbot won’t function until a new key is saved.  
3. Save a valid key, then return to **Chat Page** to start a conversation.  
4. 🎤 Press and **hold mic button to speak**.  
5. Enable auto-TTS in **Settings** to hear responses automatically.  

---

### 🐛 Troubleshooting
- **Invalid API Key** → Check key in settings  
- **No chatbot response** → Verify network connection  
- **Voice input not working** → Enable microphone permissions  
- **TTS not working** → Ensure device has a TTS engine installed  

---

### ℹ️ Tech Stack
- **GetX** → State management  
- **GetStorage** → Local storage  
- **Dotenv** → Environment variables  
- **Gemini API** → AI chatbot  
- **speech_to_text** → Voice input  
- **flutter_tts** → Voice output  
- **connectivity_plus** → Network monitoring  
- **permission_handler** → Permissions  

---

### 🙏 Closing
Thank you for using **Webview & Chatbot Prototype**!  
Your feedback and suggestions are highly valuable for future improvements. 🚀

## 👤 Contact
DovudjonUsmonov@gmail.com