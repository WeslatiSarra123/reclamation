import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'sign_up_screen.dart';// L'écran  d'inscription
import 'login_screen.dart';
import 'agent_screen.dart';
import 'client_screen.dart';
import 'chatboot_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialisation de Firebase
  runApp(MyApp());
}


Future<void> getDeviceToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token"); // Imprimer le token pour voir

}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/login': (context) => LoginScreen(),
        '/signUp':(context) => SignUpScreen(),
        '/agentHome':(context) => AgentScreen (),
        '/clientHome':(context) => ClientScreen (),
        '/chatScreen': (context) => ChatGPTScreen(),

      },
    );
  }
}

