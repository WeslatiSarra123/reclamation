import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatDetailScreen extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;

  ChatDetailScreen({
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    final timestamp = FieldValue.serverTimestamp();

    final chatId = widget.currentUserId.compareTo(widget.otherUserId) < 0
        ? '${widget.currentUserId}_${widget.otherUserId}'
        : '${widget.otherUserId}_${widget.currentUserId}';

    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'sender': widget.currentUserId,
      'text': messageText,
      'timestamp': timestamp,
      'isRead': false,
    });

    await _firestore.collection('chats').doc(chatId).set({
      'participants': [widget.currentUserId, widget.otherUserId],
      'lastMessage': messageText,
      'lastMessageTimestamp': timestamp,
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chatId = widget.currentUserId.compareTo(widget.otherUserId) < 0
        ? '${widget.currentUserId}_${widget.otherUserId}'
        : '${widget.otherUserId}_${widget.currentUserId}';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF40000),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: Text(
                widget.otherUserName[0].toUpperCase(),
                style: TextStyle(color: Color(0xFFF40000)),
              ),
            ),
            SizedBox(width: 10),
            Text(widget.otherUserName, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 4,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message['sender'] == widget.currentUserId;

                    return Row(
                      mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!isCurrentUser) CircleAvatar(
                          backgroundColor: Color(0xFFF40000),
                          radius: 20,
                          child: Text(widget.otherUserName[0].toUpperCase(), style: TextStyle(color: Colors.white)),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isCurrentUser ? Color(0xFF0077B5) : Colors.white ,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black12, offset: Offset(2, 2), blurRadius: 5)],
                          ),
                          child: Text(
                            message['text'],
                            style: TextStyle(
                              color: isCurrentUser ? Colors.white : Color(0xFF0077B5),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Écrire un message...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: CircleAvatar(
                    backgroundColor: Color(0xFF0077B5),
                    child: Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}








