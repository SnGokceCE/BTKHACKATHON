import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'api_key.dart'; // apiKey'ini buraya koymalısın

class GeminiChatPage extends StatefulWidget {
  @override
  _GeminiChatPageState createState() => _GeminiChatPageState();
}

class _GeminiChatPageState extends State<GeminiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];

  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();

    // API anahtarını api_key.dart dosyasından al
    _model = GenerativeModel(
      model: 'gemini-2.5-pro', // veya 'gemini-pro'
      apiKey: api_key,
    );
    _chat = _model.startChat();
  }

  void _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _messages.add("Sen: $input");
    });
    _controller.clear();

    try {
      final response = await _chat.sendMessage(Content.text(input));
      final text = response.text ?? "Cevap alınamadı.";
      setState(() {
        _messages.add("Bot: $text");
      });
    } catch (e) {
      setState(() {
        _messages.add("Bot: Hata oluştu: $e");
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kişisel Asistan Chatbot")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (_, index) =>
                      ListTile(title: Text(_messages[index])),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: "Mesajınızı yazın...",
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  IconButton(icon: Icon(Icons.send), onPressed: _sendMessage),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
