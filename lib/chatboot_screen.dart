import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatGPTScreen extends StatefulWidget {
  @override
  _ChatGPTScreenState createState() => _ChatGPTScreenState();
}

class _ChatGPTScreenState extends State<ChatGPTScreen> {
  final TextEditingController _controller = TextEditingController();
  final String apiKey = "YOUR_API_KEY"; // Remplacez par votre clé API
  List<Map<String, String>> messages = [];

  // Fonction pour envoyer le message à l'API OpenAI
  Future<void> sendMessage(String userMessage) async {
    setState(() {
      messages.add({"role": "user", "content": userMessage});
    });

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "model": "gpt-3.5-turbo", // Vous pouvez changer pour gpt-4 si disponible
        "messages": [
          ...messages.map((msg) => {
            "role": msg['role'],
            "content": msg['content'],
          }),
        ]
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final botMessage = responseBody['choices'][0]['message']['content'];
      setState(() {
        messages.add({"role": "assistant", "content": botMessage});
      });
    } else {
      setState(() {
        messages.add({"role": "assistant", "content": "Erreur: ${response.statusCode}"});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ChatGPT')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message['role'] == "user";
                return ListTile(
                  title: Text(
                    message['content']!,
                    textAlign: isUser ? TextAlign.end : TextAlign.start,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Entrez votre message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      sendMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}






