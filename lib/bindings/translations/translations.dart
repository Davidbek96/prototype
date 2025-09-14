import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    // ================== ENGLISH ==================
    'en_US': {
      // ---- Home Page ----
      'webview_chatbot': 'Webviw & Chatbot',
      'welcome': 'Welcome to Prototype',
      'choose_demo': 'Choose a demo to explore the features.',
      'webview_demo': 'WebView Hook Demo',
      'webview_demo_sub': 'Integrate and control web content',
      'chatbot_demo': 'Voice Chatbot Demo',
      'chatbot_demo_sub': 'Talk to the assistant & test voice flow',
      'devices': 'Connected Devices',
      'devices_sub': 'Control everything using your phone',
      'coming_soon': 'Coming Soon',
      'coming_soon_msg': 'You will be able to use this feature soon',
      'help_docs': 'Help & Docs',
      'help_docs_sub': 'Read quickstart and docs',
      'version': 'Prototype v1.0',

      // ---- Help & Docs Page ----
      'help_title': 'Help & Docs',
      'help_welcome_message':
          'Welcome to the **Webview & Chatbot Prototype**!\nThis page explains the main features and how to get started.',
      'help_features_title': 'Features',
      'help_feature_chatbot':
          'Gemini AI Chatbot – chat with real-time streaming responses.',
      'help_feature_voice_input':
          'Voice Input – press & hold mic button to talk.',
      'help_feature_tts':
          'TTS (Text-to-Speech) – the bot can read responses aloud.',
      'help_feature_webview':
          'WebView Integration – interact with embedded web content.',
      'help_feature_settings':
          'Settings Page – manage API key, language, and voice options.',
      'help_feature_help': 'Help & Docs Page – this screen!',
      'help_getting_started_title': 'Getting Started & API Key',
      'help_getting_started_step1':
          'On first install, the app loads a default API key from configuration (`.env`).',
      'help_getting_started_step1a':
          'You can delete or replace the key anytime in Settings → API Key.',
      'help_getting_started_step1b':
          'If deleted, the chatbot will stop working until you save a new key.',
      'help_getting_started_step2':
          'After saving a valid key, return to the Chat Page and start a conversation.',
      'help_getting_started_step3':
          'Use the mic button 🎤 — keep holding to talk.',
      'help_getting_started_step4':
          'Toggle auto-play TTS in Settings if you want responses spoken automatically.',
      'help_troubleshooting_title': 'Troubleshooting',
      'help_troubleshooting_key':
          'Invalid API key → double-check your key in Settings.',
      'help_troubleshooting_no_response':
          'No response from chatbot → check internet connectivity.',
      'help_troubleshooting_voice':
          'Voice not working → grant microphone permission in device settings.',
      'help_troubleshooting_tts':
          'TTS not working → make sure your device has a TTS engine installed.',
      'help_about_title': 'About',
      'help_about_description':
          'This app is a Flutter prototype built with:\n- GetX → state management\n- GetStorage → local persistence\n- Dotenv → environment keys\n- Gemini API → AI chat\n- speech_to_text → speech recognition (voice input)\n- flutter_tts → text-to-speech (bot voice output)\n- connectivity_plus → network status monitoring\n- permission_handler → runtime permission requests',
      'help_closing_note_title': 'Closing Note',
      'help_closing_note_text':
          'Thank you for exploring the **Webview & Chatbot Prototype**!\nYour feedback and suggestions will help improve future versions of the app. 🚀',
      'help_back_home': 'Back to Home',

      //Chatpage
      'gemini_chatbot': 'Gemini Chatbot',
      'settings': 'Settings',
      'stop_reply': 'Stop reply',
      'tokens': 'tokens',

      // ChatBubble
      'thinking': 'Thinking ...',
      'replay_tts': 'Replay (TTS)',
      'stop_speaking': 'Stop Speaking',
      'copy_chat': 'Copy Chat',
      'retry_message': 'Retry message',

      // MicOverlay
      'listening': 'Listening...',
      'release_to_send': 'Release to send',
      'hold_to_talk': 'Hold to talk',

      // Message
      'message': 'Message',

      // MicOnButton
      // MicOnButton
      'mic_permission_title': 'Microphone Permission Required',
      'mic_permission_content':
          'To use voice input, please allow microphone access in your device settings:\n\n• Open Settings\n• Go to App Permissions\n• Enable Microphone access',
      'cancel': 'Cancel',
      'open_settings': 'Open Settings',
      'mic_hold_title': 'Hold Microphone!',
      'mic_hold_message': 'Please keep holding microphone to talk',
      // ShowListEmpty
      'ask_me_anything': 'Ask me anything',
      'start_conversation_hint':
          'Tap the mic or type a question below to start a conversation.',

      // GeminiManager
      'missing_api_key': 'API 키 없음',
      'please_set_api_key': '설정에서 Gemini API 키를 입력해주세요.',

      // PermissionService
      'mic_required': 'Microphone required',
      'mic_perm_denied':
          'Microphone permission is permanently denied. Open app settings to enable it?',
      // ChatController
      'no_internet': 'No internet',
      'check_connection': 'Please check your connection.',
      'retrying_reason': 'Retrying: @reason',
      'gap_retrying': 'Connection gap — retrying',
      'error': 'Error',
      'stream_error': 'Stream error: @error',
      'clear_messages_title': 'Clear Messages?',
      'clear_messages_content':
          'This will remove all your chat messages. Are you sure?',
      'clear': 'Clear',
      'messages': 'Messages',
      'messages_cleared': 'All messages cleared',
      'failed_to_clear_messages': 'Failed to clear messages',
      'clear_messages': 'Clear Messages',

      //settings controller
      'settings_title': 'Settings',
      'settings_no_api_key': 'No API key provided (storage cleared)',
      'settings_api_key_saved': 'API key saved',
      'settings_invalid_api_key': 'Invalid API key (unauthorized)',
      'settings_invalid_api_key_http': 'Invalid API key (HTTP @code)',
      'settings_timeout': 'Validation timed out — check network or try again.',
      'settings_failed_validation': 'Failed to validate API key: @error',
      //webview controller
      'webview_no_text': 'No text to copy',
      'webview_user_cancelled': 'User cancelled',
      'webview_unknown_action': 'Unknown action: @action',
      'webview_invalid_json': 'Invalid JSON from JS',
      'webview_battery_charging': 'Your device is charging',
      'webview_battery_discharging': 'Your device is running on battery',
      'webview_battery_full': 'Your battery is fully charged',
      'webview_battery_unknown': 'Battery status is unknown',
      'webview_connected_wifi': 'Connected via Wi-Fi',
      'webview_connected_mobile': 'Connected via mobile data',
      'webview_connected_ethernet': 'Connected via Ethernet',
      'webview_connected_bluetooth': 'Connected via Bluetooth',
      'webview_connected_vpn': 'Connected via VPN',
      'webview_connected_other': 'Connected (other network)',
      'webview_no_internet': 'No internet connection',
      'webview_unknown': 'Unknown',

      //api_key_card
      'api_key_label': 'API Key',
      'api_key_registered': 'Registered',
      'api_key_not_registered': 'Not registered',
      'api_key_hint': 'Register a new API key',
      'api_key_tip':
          'Tip: keep your API key secret. Do not share screenshots containing the full key.',
      'copy_api_key': 'Copy API key',
      'delete_api_key': 'Delete API key',
      'save_api_key': 'Save API key',
      'no_api_key_to_copy': 'No API key to copy',
      'clear_api_key_title': 'Clear API key?',
      'clear_api_key_content': 'This will remove the stored API key.',
      'api_key_cleared': 'API key cleared',
      'delete': 'Delete',
      'more': 'More',
      'show': 'Show',
      'hide': 'Hide',

      //danger_utilities card
      'danger_utilities': 'Danger & Utilities',
      'storage': 'Storage',
      'storage_info':
          'API key and settings are stored locally on this device only.',
      'defaults': 'Defaults',
      'defaults_info':
          'Language and auto-play defaults are: TTS = en-US, STT = en-US, Auto-play TTS = off.',
      'clear_preferences': 'Clear preferences',
      'clear_all_settings_title': 'Clear all stored settings?',
      'clear_all_settings_content':
          'This removes saved language & auto-play preferences. API key will remain unless explicitly cleared.',
      'preferences_cleared': 'Preferences cleared',

      //voice_language_card
      'voice_language': 'Voice & Language',
      'auto_play_tts': 'Auto-play TTS',
      'auto_play_tts_subtitle': 'Automatically play model replies aloud',
      'tts_language': 'TTS Language',
      'stt_language': 'STT Language',
      'info': 'Info',

      'lang_english_us': 'English (US)',
      'lang_english_uk': 'English (UK)',
      'lang_korean': 'Korean',
      'lang_japanese': 'Japanese',
      'lang_french': 'French',
      'lang_german': 'German',
      'lang_spanish': 'Spanish',
      'lang_hindi': 'Hindi',
    },

    // ================== KOREAN ==================
    'ko_KR': {
      // ---- Home Page ----
      'welcome': '프로토타입에 오신 것을 환영합니다',
      'choose_demo': '기능을 탐색하려면 데모를 선택하세요.',
      'webview_demo': '웹뷰 연동 데모',
      'webview_demo_sub': '웹 콘텐츠 통합 및 제어',
      'chatbot_demo': '음성 챗봇 데모',
      'chatbot_demo_sub': '어시스턴트와 대화하고 음성 흐름 테스트',
      'devices': '연결된 기기',
      'devices_sub': '휴대폰을 이용해 모든 것을 제어하세요',
      'coming_soon': '준비 중',
      'coming_soon_msg': '곧 이 기능을 사용하실 수 있습니다',
      'help_docs': '도움말 & 문서',
      'help_docs_sub': '빠른 시작 및 문서 읽기',
      'version': '프로토타입 v1.0',

      // ---- Help & Docs Page ----
      'help_title': '도움말 & 문서',
      'help_welcome_message':
          '**웹뷰 & 챗봇 프로토타입**에 오신 것을 환영합니다!\n이 페이지는 주요 기능과 시작 방법을 설명합니다.',
      'help_features_title': '주요 기능',
      'help_feature_chatbot': 'Gemini AI 챗봇 – 실시간 스트리밍 응답과 대화.',
      'help_feature_voice_input': '음성 입력 – 마이크 버튼을 길게 눌러 말하기.',
      'help_feature_tts': 'TTS (텍스트 음성 변환) – 봇이 응답을 소리 내어 읽어줍니다.',
      'help_feature_webview': '웹뷰 통합 – 내장된 웹 콘텐츠와 상호작용.',
      'help_feature_settings': '설정 페이지 – API 키, 언어, 음성 옵션 관리.',
      'help_feature_help': '도움말 & 문서 페이지 – 현재 화면!',
      'help_getting_started_title': '시작하기 & API 키',
      'help_getting_started_step1':
          '앱 최초 설치 시, 기본 API 키가 설정 파일(`.env`)에서 로드됩니다.',
      'help_getting_started_step1a': '설정 → API 키에서 언제든 삭제하거나 교체할 수 있습니다.',
      'help_getting_started_step1b': '삭제 시, 새 키를 저장하기 전까지 챗봇은 작동하지 않습니다.',
      'help_getting_started_step2': '올바른 키를 저장한 후, 채팅 페이지로 돌아가 대화를 시작하세요.',
      'help_getting_started_step3': '마이크 버튼 🎤을 길게 눌러 말하세요.',
      'help_getting_started_step4': '설정에서 자동 재생 TTS를 켜면 응답이 자동으로 음성으로 출력됩니다.',
      'help_troubleshooting_title': '문제 해결',
      'help_troubleshooting_key': '잘못된 API 키 → 설정에서 키를 다시 확인하세요.',
      'help_troubleshooting_no_response': '챗봇이 응답하지 않음 → 인터넷 연결을 확인하세요.',
      'help_troubleshooting_voice': '음성이 작동하지 않음 → 기기 설정에서 마이크 권한을 허용하세요.',
      'help_troubleshooting_tts': 'TTS가 작동하지 않음 → 기기에 TTS 엔진이 설치되어 있는지 확인하세요.',
      'help_about_title': '앱 정보',
      'help_about_description':
          '이 앱은 Flutter로 제작된 프로토타입입니다:\n- GetX → 상태 관리\n- GetStorage → 로컬 데이터 저장\n- Dotenv → 환경 키 관리\n- Gemini API → AI 챗봇\n- speech_to_text → 음성 인식 (음성 입력)\n- flutter_tts → 텍스트 음성 변환 (봇 음성 출력)\n- connectivity_plus → 네트워크 상태 모니터링\n- permission_handler → 런타임 권한 요청',
      'help_closing_note_title': '마무리',
      'help_closing_note_text':
          '**웹뷰 & 챗봇 프로토타입**을 사용해 주셔서 감사합니다!\n여러분의 피드백과 제안은 향후 앱 개선에 큰 도움이 됩니다. 🚀',
      'help_back_home': '홈으로 돌아가기',

      //Chatpage
      'gemini_chatbot': '제미니 챗봇',
      'settings': '설정',
      'stop_reply': '응답 중지',
      'tokens': '토큰',

      // ChatBubble
      'thinking': '생각 중 ...',
      'replay_tts': '다시 듣기 (TTS)',
      'stop_speaking': '말하기 중지',
      'copy_chat': '채팅 복사',
      'retry_message': '다시 시도',

      // MicOverlay
      'listening': '듣는 중...',
      'release_to_send': '보내려면 놓으세요',
      'hold_to_talk': '누르고 말하세요',

      // Message
      'message': '메시지',

      // MicOnButton
      'mic_permission_title': '마이크 권한 필요',
      'mic_permission_content':
          '음성 입력을 사용하려면 기기 설정에서 마이크 접근을 허용해주세요:\n\n• 설정 열기\n• 앱 권한으로 이동\n• 마이크 접근 허용',
      'cancel': '취소',
      'open_settings': '설정 열기',
      'mic_hold_title': '마이크를 누르고 계세요!',
      'mic_hold_message': '말씀하려면 마이크를 계속 누르고 계세요',

      // ShowListEmpty
      'ask_me_anything': '아무거나 물어보세요',
      'start_conversation_hint': '대화를 시작하려면 마이크를 누르거나 질문을 입력하세요.',

      // GeminiManager
      'missing_api_key': 'API 키 없음',
      'please_set_api_key': '설정에서 Gemini API 키를 입력해주세요.',
      // PermissionService (Korean)
      'mic_required': '마이크 필요',
      'mic_perm_denied': '마이크 권한이 영구적으로 거부되었습니다. 앱 설정을 열어 권한을 허용하시겠습니까?',
      // ChatController (Korean)
      'no_internet': '인터넷 없음',
      'check_connection': '연결을 확인해주세요.',
      'retrying_reason': '재시도 중: @reason',
      'gap_retrying': '연결 끊김 — 재시도 중',
      'error': '오류',
      'stream_error': '스트림 오류: @error',
      'clear_messages_title': '메시지 삭제?',
      'clear_messages_content': '모든 채팅 메시지가 삭제됩니다. 계속하시겠습니까?',
      'clear': '삭제',
      'messages': '메시지',
      'messages_cleared': '모든 메시지가 삭제되었습니다',

      'failed_to_clear_messages': '메시지를 삭제하지 못했습니다',

      //settings controller
      'settings_title': '설정',
      'settings_no_api_key': 'API 키가 제공되지 않았습니다 (저장소가 초기화됨)',
      'settings_api_key_saved': 'API 키가 저장되었습니다',
      'settings_invalid_api_key': '잘못된 API 키 (권한 없음)',
      'settings_invalid_api_key_http': '잘못된 API 키 (HTTP @code)',
      'settings_timeout': '검증 시간이 초과되었습니다 — 네트워크를 확인하거나 다시 시도하세요.',
      'settings_failed_validation': 'API 키 검증 실패: @error',

      //webview_controller
      'webview_no_text': '복사할 텍스트가 없습니다',
      'webview_user_cancelled': '사용자가 취소했습니다',
      'webview_unknown_action': '알 수 없는 액션: @action',
      'webview_invalid_json': 'JS에서 잘못된 JSON이 전송됨',
      'webview_battery_charging': '장치가 충전 중입니다',
      'webview_battery_discharging': '장치가 배터리로 실행 중입니다',
      'webview_battery_full': '배터리가 완전히 충전되었습니다',
      'webview_battery_unknown': '배터리 상태를 알 수 없습니다',
      'webview_connected_wifi': 'Wi-Fi에 연결됨',
      'webview_connected_mobile': '모바일 데이터에 연결됨',
      'webview_connected_ethernet': '이더넷에 연결됨',
      'webview_connected_bluetooth': '블루투스에 연결됨',
      'webview_connected_vpn': 'VPN에 연결됨',
      'webview_connected_other': '기타 네트워크에 연결됨',
      'webview_no_internet': '인터넷 연결 없음',
      'webview_unknown': '알 수 없음',

      //api_key_card
      'api_key_label': 'API 키',
      'api_key_registered': '등록됨',
      'api_key_not_registered': '등록되지 않음',
      'api_key_hint': '새 API 키 등록',
      'api_key_tip': '팁: API 키를 비밀로 유지하세요. 전체 키가 포함된 스크린샷을 공유하지 마세요.',
      'copy_api_key': 'API 키 복사',
      'delete_api_key': 'API 키 삭제',
      'save_api_key': 'API 키 저장',
      'no_api_key_to_copy': '복사할 API 키가 없습니다',
      'clear_api_key_title': 'API 키를 삭제하시겠습니까?',
      'clear_api_key_content': '저장된 API 키가 제거됩니다.',
      'api_key_cleared': 'API 키가 삭제되었습니다',
      'delete': '삭제',
      'more': '더보기',
      'show': '표시',
      'hide': '숨기기',

      //danger_utilities card
      'danger_utilities': '위험 및 유틸리티',
      'storage': '저장소',
      'storage_info': 'API 키와 설정은 이 장치에만 로컬로 저장됩니다.',
      'defaults': '기본값',
      'defaults_info':
          '언어 및 자동 재생 기본값: TTS = en-US, STT = en-US, 자동 재생 TTS = 끄기.',
      'clear_preferences': '환경설정 삭제',
      'clear_all_settings_title': '저장된 모든 설정을 삭제하시겠습니까?',
      'clear_all_settings_content':
          '저장된 언어 및 자동 재생 환경설정이 제거됩니다. API 키는 명시적으로 삭제하지 않는 한 남습니다.',
      'preferences_cleared': '환경설정이 삭제되었습니다',
      'clear_messages': '메시지 삭제',
      //voice_language_card
      'voice_language': '음성 및 언어',
      'auto_play_tts': 'TTS 자동 재생',
      'auto_play_tts_subtitle': '모델 응답을 자동으로 소리 내어 재생',
      'tts_language': 'TTS 언어',
      'stt_language': 'STT 언어',
      'info': '알림',
      'lang_english_us': '영어 (미국)',
      'lang_english_uk': '영어 (영국)',
      'lang_korean': '한국어',
      'lang_japanese': '일본어',
      'lang_french': '프랑스어',
      'lang_german': '독일어',
      'lang_spanish': '스페인어',
      'lang_hindi': '힌디어',
      'webview_chatbot': '웹뷰 & 챗봇',
    },
  };
}
