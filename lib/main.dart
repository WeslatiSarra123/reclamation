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
import 'package:flutter_stripe/flutter_stripe.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(); // Initialisation de Firebase
  } catch (e) {
    print('Erreur lors de l\'initialisation de Firebase: $e');
  }
  try {
    // Initialisation de Stripe (Clé publique uniquement !)
    Stripe.publishableKey = "pk_test_51MyjRmG1Pb689ekQXSnaNb3T5zlM4AtWEw9ilaAeGxy07b4tVsjUyEqek0oRllNtoEhFkZ6TSx6JY6lww6sQTM5s00LO1tBdGY";
    await Stripe.instance.applySettings();
    print('Stripe initialisé avec succès.');
  } catch (e) {
    print('Erreur lors de l\'initialisation de Stripe: $e');
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


