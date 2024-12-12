import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reclamation/client_reclamation_screen.dart';
import 'package:reclamation/client_screen.dart';
import 'package:reclamation/edit_profile_client.dart';
import 'package:reclamation/chat_screen.dart';

class ReviewScreen extends StatefulWidget {
  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _selectedStars = 0; // Nombre d'étoiles sélectionnées
  final TextEditingController _commentController = TextEditingController();

  // Fonction pour enregistrer un avis
  Future<void> saveReview() async {
    if (_selectedStars == 0 || _commentController.text.isEmpty) {
      _showErrorDialog('Veuillez donner une note et un commentaire.');
      return;
    }

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showErrorDialog('Vous devez être connecté pour laisser un avis.');
      return;
    }

    try {
      // Récupérer les données utilisateur depuis Firestore
      DocumentSnapshot<Map<String, dynamic>> userData = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      String userName = userData.data()?['name'] ?? 'Utilisateur inconnu';

      // Ajouter l'avis dans la collection "reviews"
      await FirebaseFirestore.instance.collection('reviews').add({
        'stars': _selectedStars,
        'comment': _commentController.text,
        'name': userName, // Utiliser le nom d'utilisateur depuis Firestore
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showSuccessDialog('Merci pour votre avis !');

      // Réinitialiser le formulaire après la soumission réussie
      setState(() {
        _selectedStars = 0;
        _commentController.clear();
      });
    } catch (e) {
      _showErrorDialog('Erreur lors de l\'enregistrement : ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Icon(Icons.error, color: Colors.red, size: 40),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Icon(Icons.check_circle, color: Colors.green, size: 40),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red,
          child: Text(
            review['name']?.substring(0, 1).toUpperCase() ?? 'U',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          review['name'] ?? 'Utilisateur inconnu',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              review['comment'] ?? 'Aucun commentaire.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            Row(
              children: List.generate(
                review['stars'] ?? 0,
                    (index) => Icon(Icons.star, color: Colors.amber, size: 20),
              ),
            ),
          ],
        ),
        trailing: Text(
          review['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(review['timestamp'].seconds * 1000).toString().substring(0, 16)
              : 'Date inconnue',
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Avis des utilisateurs'),
        backgroundColor: Color(0xFFF40000),
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFFF40000)),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.assignment),
              title: Text('Mes réclamations'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientReclamationsScreen())),
            ),
            ListTile(
              leading: Icon(Icons.star),
              title: Text('Avis'),
             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen())),
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
              title: Text('Home'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ClientScreen())),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Modifier Profil'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileClientScreen())),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Donnez votre avis', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) => GestureDetector(
                      onTap: () => setState(() => _selectedStars = index + 1),
                      child: Icon(
                        Icons.star,
                        color: index < _selectedStars ? Colors.amber : Colors.grey,
                        size: 40,
                      ),
                    )),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: 'Votre commentaire',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: saveReview,
                      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFF40000),
                        foregroundColor: Colors.white,),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text('Enregistrer', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('reviews').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Erreur de chargement'));
                return ListView(
                  shrinkWrap: true,
                  children: snapshot.data!.docs.map((doc) => _buildReviewItem(doc.data() as Map<String, dynamic>)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

