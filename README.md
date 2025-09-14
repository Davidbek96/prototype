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
└── features
  │  ├── chat
  │  │ ├── domain
  │  │ │ └── chat_stream_manager.dart
  │  │ ├── models
  │  │ │ ├── chat_model.dart
  │  │ │ ├── gemini_adapter.dart
  │  │ │ └── gemini_manager.dart
  │  │ ├── services
  │  │ │ ├── stt_service.dart
  │  │ │ ├── transient_message_service.dart
  │  │ │ └── tts_service.dart
  │  │ ├── widgets
  │  │ │ ├── action_card.dart
  │  │ │ ├── chat_bubble.dart
  │  │ │ ├── input_area.dart
  │  │ │ ├── mic_pulse_btn.dart
  │  │ │ └── show_list_empty.dart
  │  │ ├── chat_binding.dart
  │  │ ├── chat_controller.dart
  │  │ └── chat_page.dart
  │  │
  │  ├── help_docs
  │  │ └── help_docs_page.dart
  │  │
  │  ├── home
  │  │ └── home_page.dart
  │  │
  │  ├── settings
  │  │ ├── widgets
  │  │ │ ├── api_key_card.dart
  │  │ │ ├── danger_utilities_card.dart
  │  │ │ ├── voice_language_card.dart
  │  │ │ └── settings_controller.dart
  │  │ └── settings_page.dart
  │  │
  │  └── webview
  │   └── bridge
  │    └── webview_page.dart
  │ 
  ├─ shared
  │  ├── services
  │  └── translations
  ├─ app.dart
  └─ main.dart

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