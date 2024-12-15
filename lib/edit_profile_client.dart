import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reclamation/client_screen.dart';
import 'package:reclamation/client_reclamation_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:reclamation/avis_client.dart';
import 'package:reclamation/chat_screen.dart';

class EditProfileClientScreen extends StatefulWidget {
  @override
  _EditProfileClientScreenState createState() => _EditProfileClientScreenState();
}

class _EditProfileClientScreenState extends State<EditProfileClientScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;

        _nameController.text = userData['name'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
      }
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'name': _nameController.text,
          'phone': _phoneController.text,
        });

        _showDialog("Succès", "Profil mis à jour avec succès !");
      } catch (e) {
        _showDialog("Erreur", "Erreur lors de la mise à jour du profil.");
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK")
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Modifier le profil"),
        backgroundColor: Color(0xFFF40000),
        foregroundColor: Colors.white,
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
              title: Text('Mes réclamations'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MesReclamationsPage()));
                },
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Nom",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              readOnly: true,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: "Numéro de téléphone",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text("Sauvegarder les modifications"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF40000),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}