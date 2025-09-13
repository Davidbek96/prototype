import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class HelpDocsPage extends StatelessWidget {
  const HelpDocsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const String helpContent = """
## 📖 Help & Docs

Welcome to the **Webview & Chatbot Prototype**!  
This page explains the main features and how to get started.

---

## ✨ Features
- 🤖 **Gemini AI Chatbot** – chat with real-time streaming responses.
- 🎙 **Voice Input** – press & hold mic button to talk.
- 🔊 **TTS (Text-to-Speech)** – the bot can read responses aloud.
- 🌐 **WebView Integration** – interact with embedded web content.
- ⚙️ **Settings Page** – manage API key, language, and voice options.
- 📖 **Help & Docs Page** – this screen!

---

## 🚀 Getting Started & API Key
1. On **first install**, the app loads a default API key from configuration (`.env`).  
   - You can **delete or replace the key** anytime in **Settings → API Key**.  
   - If deleted, the chatbot will stop working until you save a new key.
2. After saving a valid key, return to the **Chat Page** and start a conversation.  
3. Use the mic button 🎤 — **keep holding** to talk.  
4. Toggle auto-play TTS in **Settings** if you want responses spoken automatically.  

---

## 🐛 Troubleshooting
- **Invalid API key** → double-check your key in Settings.
- **No response from chatbot** → check internet connectivity.
- **Voice not working** → grant microphone permission in device settings.
- **TTS not working** → make sure your device has a TTS engine installed.

---

## ℹ️ About
This app is a Flutter prototype built with:
- **GetX** → state management
- **GetStorage** → local persistence
- **Dotenv** → environment keys
- **Gemini API** → AI chat
- **speech_to_text** → speech recognition (voice input)
- **flutter_tts** → text-to-speech (bot voice output)
- **connectivity_plus** → network status monitoring
- **permission_handler** → runtime permission requests

---

## 🙏 Closing Note
Thank you for exploring the **Webview & Chatbot Prototype**!  
Your feedback and suggestions will help improve future versions of the app. 🚀
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
                        // space between block elements (this affects horizontal rules too)
                        blockSpacing: 12.0,
                        // subtle rule appearance
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
                  label: const Text("Back to Home"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
