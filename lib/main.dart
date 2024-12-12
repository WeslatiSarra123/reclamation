import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'sign_up_screen.dart'; // L'écran d'inscription
import 'login_screen.dart';
import 'agent_screen.dart';
import 'client_screen.dart';
import 'chatboot_screen.dart';
import 'splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(); // Initialisation de Firebase
  } catch (e) {
    print('Erreur lors de l\'initialisation de Firebase: $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/signUp': (context) => SignUpScreen(),
        '/agentHome': (context) => AgentScreen(),
        '/clientHome': (context) => ClientScreen(),
        '/chatScreen': (context) => ChatGPTScreen(),
      },
    );
  }
}


