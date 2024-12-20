import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reclamation/edit_profile.dart';
import 'package:reclamation/avis_agent.dart';
import 'package:reclamation/agent_screen.dart';
import 'package:reclamation/reclamation_details.dart';
import 'package:reclamation/historique.dart';
import 'package:reclamation/chat_screen.dart';
class AgentReclamationsScreen extends StatefulWidget {
  @override
  _AgentReclamationsScreenState createState() => _AgentReclamationsScreenState();
}

class _AgentReclamationsScreenState extends State<AgentReclamationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> _getReclamations() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('reclamations')
        .where('status', isEqualTo: 'En attente')
        .where('agentId', isEqualTo: currentUser.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Réclamations en attente'),
        backgroundColor: Color(0xFFF40000),
        foregroundColor: Colors.white,
      ),
      drawer: _buildDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getReclamations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erreur de chargement des réclamations"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucune réclamation en attente', style: TextStyle(fontSize: 16)));
          }

          var reclamations = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: reclamations.length,
            itemBuilder: (context, index) {
              var reclamation = reclamations[index];
              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFFF40000),
                    child: Icon(Icons.description, color: Colors.white),
                  ),
                  title: Text(
                    'Transaction: ${reclamation['transactionType']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      Text('Numéro: ${reclamation['phoneNumber']}', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 5),
                      Text('Date: ${reclamation['transactionDate']}', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.remove_red_eye, color: Color(0xFFF40000)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReclamationDetailsScreen(reclamation: reclamation),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFF40000)),
            child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          _buildDrawerItem(Icons.assignment, 'Réclamations', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AgentReclamationsScreen()));
          }),
          _buildDrawerItem(Icons.star, 'Voir Avis', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewsAgentScreen()));
          }),
          _buildDrawerItem(Icons.history, 'Historique', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AgentReclamationHistoriquesScreen()));
          }),
          _buildDrawerItem(Icons.assignment, 'Chat', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen()));
          }),
          _buildDrawerItem(Icons.home, 'Accueil', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AgentScreen()));
          }),
          _buildDrawerItem(Icons.settings, 'Modifier Mes Informations', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen()));
          }),
          _buildDrawerItem(Icons.logout, 'Déconnexion', () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacementNamed(context, '/login');
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFFF40000)),
      title: Text(title, style: TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }
}







