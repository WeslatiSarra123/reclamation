import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';


class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _role = 'client'; // Valeur par défaut pour le rôle
  final _formKey = GlobalKey<FormState>();

  // Fonction pour créer un nouvel utilisateur et ajouter les détails dans Firestore
  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        final email = _emailController.text;
        final password = _passwordController.text;

        // Créer un utilisateur avec Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Récupérer l'ID de l'utilisateur
        String userId = userCredential.user!.uid;

        // Créer un document dans Firestore sous la collection 'users'
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'name': _nameController.text,
          'email': email,
          'phone': _phoneController.text,
          'role': _role,
          'image': 'assets/images/profile_default.jpg',
        });

        // Affichage d'un message de succès ou navigation
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Inscription réussie")));
        // Attendez un court instant pour que l'utilisateur puisse voir le message
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer un compte', style: TextStyle(fontFamily: 'Ooredoo', fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Color(0xFFF40000), // Couleur inspirée d'Ooredoo
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // Logo d'Ooredoo
                Image.asset(
                  'assets/images/ooredoo_logo.png', // Assurez-vous que le logo est bien dans ce répertoire
                  height: 150,
                ),
                SizedBox(height: 20),

                // Nom d'utilisateur
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    fillColor: Colors.grey.shade100,
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    fillColor: Colors.grey.shade100,
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Mot de passe
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    fillColor: Colors.grey.shade100,
                    filled: true,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Numéro de téléphone
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    fillColor: Colors.grey.shade100,
                    filled: true,
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un numéro de téléphone';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Sélection du rôle
                Text('Sélectionnez votre rôle:', style: TextStyle(color: Colors.red)),
                Row(
                  children: <Widget>[
                    Radio<String>(
                      value: 'client',
                      groupValue: _role,
                      onChanged: (value) {
                        setState(() {
                          _role = value!;
                        });
                      },
                    ),
                    Text("Client", style: TextStyle(color: Colors.black)),
                    SizedBox(width: 20),
                    Radio<String>(
                      value: 'agent',
                      groupValue: _role,
                      onChanged: (value) {
                        setState(() {
                          _role = value!;
                        });
                      },
                    ),
                    Text("Agent", style: TextStyle(color: Colors.black)),
                  ],
                ),
                SizedBox(height: 20),

                // Bouton d'inscription avec ombre et bords arrondis
                ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF40000), // Utilisation de backgroundColor au lieu de primary
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 5,
                  ),
                  child: Text('S\'inscrire', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold , color: Colors.white)),
                ),
                SizedBox(height: 20),

                // Texte de redirection
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Vous avez déjà un compte? "),
                    TextButton(
                      onPressed: () {
                        // Rediriger vers l'écran de connexion
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text('Se connecter', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


