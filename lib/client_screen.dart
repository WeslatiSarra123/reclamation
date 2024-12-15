import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'reclamation_form.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:reclamation/avis_client.dart';
import 'package:reclamation/edit_profile_client.dart';
import 'package:reclamation/chat_screen.dart';
import 'package:reclamation/client_reclamation_screen.dart';

class ClientScreen extends StatefulWidget {
  @override
  _ClientScreenState createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  String? clientId; // Déclare clientId
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  LatLng _currentPosition = LatLng(12.9716, 77.5946); // Position initiale par défaut
  bool _isLocationFetched = false;
  bool _isLocationError = false;
  String _locationErrorMessage = '';
  final MapController _mapController = MapController();

  // Liste dynamique des positions des agents
  List<Map<String, dynamic>> _agentPositions = [];
  LatLng? _selectedAgentPosition;
  String? _selectedAgentPhone;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      clientId = user?.uid; // Maintenant, clientId est disponible
    });
    _initializeFCM();
    _requestPermissions();
    _getCurrentLocation();
    _fetchAgentPositions();
  }

  // Demande de permissions
  Future<void> _requestPermissions() async {
    await Permission.location.request();
    await Permission.phone.request();
    await Permission.sms.request();
  }

  Future<void> _initializeFCM() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await _updateFCMToken();
        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          await _updateFCMToken(newToken);
        });

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('📩 ${message.notification?.title ?? 'Message reçu'}')),
          );
        });
      }
    } catch (e) {
      print("Erreur d'initialisation FCM: $e");
    }
  }

  Future<void> _updateFCMToken([String? newToken]) async {
    try {
      String? token = newToken ?? await _firebaseMessaging.getToken();
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && token != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Erreur de mise à jour du jeton FCM: $e");
    }
  }

  // Fonction pour obtenir la position actuelle
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocationError = true;
          _locationErrorMessage = "Les services de localisation sont désactivés.";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocationError = true;
          _locationErrorMessage = "La permission de localisation a été refusée définitivement.";
        });
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          setState(() {
            _isLocationError = true;
            _locationErrorMessage = "La permission de localisation a été refusée.";
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLocationFetched = true;
        _isLocationError = false;
      });
    } catch (e) {
      setState(() {
        _isLocationError = true;
        _locationErrorMessage = "Erreur de géolocalisation : $e";
      });
    }
  }

  // Fonction pour récupérer les positions des agents depuis Firestore
  // Fonction pour récupérer les positions des agents depuis Firestore
  Future<void> _fetchAgentPositions() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'agent').get();

      List<Map<String, dynamic>> fetchedPositions = querySnapshot.docs.map((doc) {
        double latitude = doc['latitude'];
        double longitude = doc['longitude'];
        return {
          'latitude': latitude,
          'longitude': longitude,
          'phone': doc['phone'],
          'name': doc['name'],
          'email': doc['email'],
          'id': doc.id,
        };
      }).toList();

      setState(() {
        _agentPositions = fetchedPositions;
      });
    } catch (e) {
      print("Erreur lors de la récupération des positions des agents : $e");
    }
  }


  // Gestion des appels téléphoniques
  Future<void> _makePhoneCall(String phone) async {
    if (await Permission.phone.request().isGranted) {
      final Uri url = Uri(scheme: 'tel', path: phone);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        print("Impossible de lancer l'appel");
      }
    } else {
      print("Permission d'appel refusée");
    }
  }

  // Gestion de l'envoi de SMS
  Future<void> _sendSms(String phone) async {
    if (await Permission.sms.request().isGranted) {
      final Uri url = Uri(scheme: 'sms', path: phone);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        print("Impossible d'envoyer le SMS");
      }
    } else {
      print("Permission SMS refusée");
    }
  }

  // Ouverture du formulaire de réclamation
  void _openReclamationForm(BuildContext context, String agentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ReclamationForm(agentId: agentId , clientId: clientId!),
        );
      },
    );
  }

  // Menu des actions pour un agent sélectionné
  // Menu des actions pour un agent sélectionné
  void _showAgentActionMenu(BuildContext context, String phone, String agentId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => _makePhoneCall(phone),
                icon: Icon(Icons.phone, color: Colors.green),
              ),
              IconButton(
                onPressed: () => _sendSms(phone),
                icon: Icon(Icons.message, color: Colors.blue),
              ),
              IconButton(
                icon: Icon(Icons.report_problem, color: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  _openReclamationForm(context, agentId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carte Client'),
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
              leading: Icon(Icons.comment),
              title: Text('Avis '),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.mark_chat_unread),
              title: Text('Chat'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(),  // Assurez-vous que UserListScreen est bien importé
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Modifier Profil'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileClientScreen()));
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
      body: _isLocationFetched
          ? Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(center: _currentPosition, zoom: 15.0),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition,
                    builder: (ctx) => Icon(Icons.location_on, color: Colors.blue, size: 50.0),
                  ),
                  ..._agentPositions.map((agent) {
                    LatLng agentPosition = LatLng(agent['latitude'], agent['longitude']);
                    return Marker(
                      point: agentPosition,
                      builder: (ctx) => GestureDetector(
                        onTap: () {
                          _showAgentActionMenu(context, agent['phone'], agent['id']);
                        },
                        child: Icon(Icons.store, color: Colors.red, size: 40.0),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: EdgeInsets.all(8),
              color: Colors.white,
              child: Text(
                'Votre position et les agents à proximité',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              child: Icon(Icons.my_location),
              backgroundColor: Colors.blue,
            ),
          ),
        ],
      )
          : Center(
        child: _isLocationError
            ? Text(_locationErrorMessage, style: TextStyle(color: Colors.red))
            : CircularProgressIndicator(),
      ),
    );
  }
}
