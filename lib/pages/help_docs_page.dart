import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class HelpDocsPage extends StatelessWidget {
  const HelpDocsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const String helpContent = """
## 📖 도움말 & 문서

**Webview & Chatbot Prototype**에 오신 것을 환영합니다!  
이 페이지는 주요 기능과 시작 방법을 설명합니다.

---

## ✨ 주요 기능
- 🤖 **Gemini AI 챗봇** – 실시간 스트리밍 응답으로 대화하기
- 🎙 **음성 입력** – 마이크 버튼을 길게 눌러 말하기
- 🔊 **TTS (텍스트 읽기)** – 챗봇이 응답을 소리 내어 읽기
- 🌐 **WebView 통합** – 내장 웹 콘텐츠와 상호작용하기
- ⚙️ **설정 페이지** – API 키, 언어, 음성 옵션 관리
- 📖 **도움말 & 문서 페이지** – 바로 이 화면!

---

## 🚀 시작하기 & API 키
1. **처음 설치 시**, 앱은 설정 파일(`.env`)에서 기본 API 키를 불러옵니다.  
   - 언제든지 **설정 → API 키**에서 키를 삭제하거나 교체할 수 있습니다.  
   - 삭제 시, 새 키를 저장하기 전까지 챗봇이 작동하지 않습니다.
2. 유효한 키를 저장한 후, **채팅 페이지**로 돌아가 대화를 시작하세요.  
3. 🎤 마이크 버튼을 **길게 누른 상태로 말하기**  
4. **설정**에서 자동 재생 TTS를 켜면 응답을 자동으로 읽어줍니다.

---

## 🐛 문제 해결
- **유효하지 않은 API 키** → 설정에서 키를 다시 확인하세요.
- **챗봇 응답 없음** → 인터넷 연결 상태를 확인하세요.
- **음성 입력 안 됨** → 기기 설정에서 마이크 권한을 허용하세요.
- **TTS 작동 안 함** → 기기에 TTS 엔진이 설치되어 있는지 확인하세요.

---

## ℹ️ 앱 정보
이 앱은 다음으로 제작된 Flutter 프로토타입입니다:
- **GetX** → 상태 관리
- **GetStorage** → 로컬 저장소
- **Dotenv** → 환경 변수 관리
- **Gemini API** → AI 채팅
- **speech_to_text** → 음성 인식 (음성 입력)
- **flutter_tts** → 텍스트 읽기 (챗봇 음성 출력)
- **connectivity_plus** → 네트워크 상태 모니터링
- **permission_handler** → 런타임 권한 요청

---

## 🙏 마무리
**Webview & Chatbot Prototype**을 사용해 주셔서 감사합니다!  
여러분의 피드백과 제안은 앱의 향후 버전 개선에 큰 도움이 됩니다. 🚀
    """;

    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: backgroundColor,
                child: Markdown(
                  data: helpContent,
                  padding: const EdgeInsets.all(16.0),
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                      .copyWith(
                        h1: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                        h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo.shade400,
                        ),
                        p: Theme.of(context).textTheme.bodyMedium,
                        blockSpacing: 12.0,
                        horizontalRuleDecoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade300,
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home),
                  label: const Text("홈으로 돌아가기"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
