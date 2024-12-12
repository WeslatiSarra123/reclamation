import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fonction de connexion classique
  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final email = _emailController.text;
        final password = _passwordController.text;

        // Connexion avec Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Vérifier si l'utilisateur existe et récupérer ses informations depuis Firestore
        String userId = userCredential.user!.uid;
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

        // Vérifier si l'utilisateur existe dans Firestore et rediriger selon son rôle
        if (userDoc.exists) {
          String role = userDoc['role'];
          if (role == 'client') {
            Navigator.pushReplacementNamed(context, '/clientHome');
          } else if (role == 'agent') {
            Navigator.pushReplacementNamed(context, '/agentHome');
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : ${e.toString()}")));
      }
    }
  }

  // Fonction de connexion via Google
  Future<void> _loginWithGoogle() async {
    try {
      // Initialiser Google SignIn
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // L'utilisateur a annulé la connexion avec Google
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Créer un credential pour Firebase Auth
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Connexion avec Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Récupérer l'ID utilisateur et les données Firestore
      String userId = userCredential.user!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      // Vérifier si l'utilisateur existe dans Firestore et rediriger selon son rôle
      if (userDoc.exists) {
        String role = userDoc['role'];
        if (role == 'client') {
          Navigator.pushReplacementNamed(context, '/clientHome');
        } else if (role == 'agent') {
          Navigator.pushReplacementNamed(context, '/agentHome');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur Google Sign-In: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connexion', style: TextStyle(fontFamily: 'Ooredoo', fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Color(0xFFF40000), // Couleur inspirée d'Ooredoo
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              // Champ Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  prefixIcon: Icon(Icons.email, color: Colors.red),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Champ Mot de Passe
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  prefixIcon: Icon(Icons.lock, color: Colors.red),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un mot de passe';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Bouton de connexion avec email et mot de passe
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF40000), // Rouge Ooredoo
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  'Se connecter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),

              // Bouton de connexion via Google
              ElevatedButton.icon(
                onPressed: _loginWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Couleur pour Google
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 5,
                ),
                icon: Icon(Icons.account_circle, color: Colors.white),
                label: Text(
                  'Se connecter avec Google',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Veuillez entrer une adresse e-mail valide.')),

                    );
                    return;
                  }
                  try {
                    await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('E-mail de réinitialisation envoyé !')),

                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur : ${e.toString()}')),

                    );
                  }
                },
                child: Text(
                  'Mot de passe oublié ?',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Vous n'avez pas de compte ? ",
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Naviguer vers l'écran d'inscription
                      Navigator.pushNamed(context, '/signUp');
                    },
                    child: Text(
                      "S'inscrire",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF40000), // Rouge Ooredoo
                      ),
                    ),
                  ),
                ],
              ),
              // Rendre le bouton adaptable au clavier
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: IconButton(
                    icon: SizedBox(
                      width: 30,  // Largeur de l'icône
                      height: 30, // Hauteur de l'icône
                      child: Image.asset('assets/images/openai_icon.png'),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/chatScreen');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

