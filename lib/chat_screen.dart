import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'chat.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? currentUserId = user?.uid;

    if (currentUserId == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Veuillez vous connecter pour accéder à la messagerie.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        backgroundColor: Color(0xFFF40000),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Liste des utilisateurs en haut (horizontal)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final users = snapshot.data!.docs;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    if (user.id == currentUserId) return SizedBox.shrink(); // Exclure l'utilisateur connecté

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                currentUserId: currentUserId,
                                otherUserId: user.id,
                                otherUserName: user['name'],
                              ),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Color(0xFFF40000),
                              child: Text(
                                user['name'][0].toUpperCase(),
                                style: TextStyle(color: Colors.white, fontSize: 20),
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              user['name'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Liste des conversations en dessous avec un Expanded
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: currentUserId) // Récupérer les chats où l'utilisateur est participant
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final chats = snapshot.data!.docs;

                // Trier les chats par la date du dernier message (du plus récent au plus ancien)
                chats.sort((a, b) {
                  final aTimestamp = a['lastMessageTimestamp'] != null
                      ? (a['lastMessageTimestamp'] as Timestamp).toDate()
                      : DateTime.now();
                  final bTimestamp = b['lastMessageTimestamp'] != null
                      ? (b['lastMessageTimestamp'] as Timestamp).toDate()
                      : DateTime.now();
                  return bTimestamp.compareTo(aTimestamp); // Trier du plus récent au plus ancien
                });

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final lastMessage = chat['lastMessage'] ?? '';
                    final lastMessageTimestamp = chat['lastMessageTimestamp'] != null
                        ? (chat['lastMessageTimestamp'] as Timestamp).toDate()
                        : null;

                    // Récupération de l'ID de l'autre utilisateur
                    final otherUserId = chat['participants'].firstWhere((id) => id != currentUserId);

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                      builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return ListTile(
                            title: Text('Chargement...'),
                          );
                        }
                        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                          return SizedBox.shrink(); // Ne rien afficher si l'utilisateur n'est pas trouvé
                        }
                        // Récupération du nom de l'autre utilisateur
                        final otherUserName = userSnapshot.data!['name'];

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: Color(0xFFF40000),
                              child: Text(
                                otherUserName[0].toUpperCase(),
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ),
                            title: Text(
                              '$otherUserName',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(lastMessage, overflow: TextOverflow.ellipsis),
                            trailing: lastMessageTimestamp != null
                                ? Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yy').format(lastMessageTimestamp),
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  '${lastMessageTimestamp.hour}:${lastMessageTimestamp.minute}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            )
                                : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatDetailScreen(
                                    currentUserId: currentUserId,
                                    otherUserId: otherUserId,
                                    otherUserName: otherUserName,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }}


