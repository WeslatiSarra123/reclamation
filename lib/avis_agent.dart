import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:reclamation/agent_reclamation_screen.dart';
import 'package:reclamation/edit_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reclamation/chat_screen.dart';
import 'package:reclamation/historique.dart';
import 'package:reclamation/agent_screen.dart';
class ReviewsAgentScreen extends StatefulWidget {
  @override
  _ReviewsAgentScreenState createState() => _ReviewsAgentScreenState();
}

class _ReviewsAgentScreenState extends State<ReviewsAgentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Avis des utilisateurs'),
        backgroundColor: Color(0xFFF40000),
        foregroundColor: Colors.white, // Thème Ooredoo
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFFF40000)),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.assignment),
              title: Text('Réclamations'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AgentReclamationsScreen()),
              ),
            ),
            ListTile(
              leading: Icon(Icons.star),
              title: Text('Voir Avis '),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewsAgentScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.mark_chat_unread),
              title: Text('Chat'),
              onTap: () {
                // Naviguer vers la page UserListScreen avec l'ID de l'utilisateur actuel
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(),  // Assurez-vous que UserListScreen est bien importé
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Accueil'),
              onTap: () {
                // Naviguer vers la page UserListScreen avec l'ID de l'utilisateur actuel
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AgentScreen(),  // Assurez-vous que UserListScreen est bien importé
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Historique'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AgentReclamationHistoriquesScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Modifier Profil'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Déconnexion'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .orderBy('timestamp', descending: true) // Trier par date de création
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur lors du chargement des avis.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucun avis disponible.'));
          }

          // Récupérer la liste des avis
          final reviews = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              var review = reviews[index].data() as Map<String, dynamic>;

              int stars = review['stars'] ?? 0;
              String comment = review['comment'] ?? 'Aucun commentaire';
              String userName = review['name'] ?? 'Utilisateur inconnu';
              Timestamp? timestamp = review['timestamp'] as Timestamp?;
              String formattedDate = timestamp != null
                  ? DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch).toString()
                  : 'Date inconnue';

              return Card(
                margin: EdgeInsets.all(10.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Afficher le nom de l'utilisateur
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            formattedDate.split(' ')[0], // Affiche la date au format 'YYYY-MM-DD'
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      // Afficher les étoiles
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < stars ? Icons.star : Icons.star_border,
                            color: Colors.orange,
                            size: 20,
                          );
                        }),
                      ),
                      SizedBox(height: 10),
                      // Afficher le commentaire de l'utilisateur
                      Text(
                        comment,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
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
    );
  }
}
