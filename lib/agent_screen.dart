import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:reclamation/agent_reclamation_screen.dart';
import 'package:reclamation/edit_profile.dart';
import 'package:reclamation/avis_agent.dart';
import 'package:reclamation/chat_screen.dart';

class AgentScreen extends StatefulWidget {
  @override
  _AgentScreenState createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  LatLng _currentPosition = LatLng(12.9716, 77.5946);
  bool _isLocationFetched = false;

  StreamSubscription<Position>? _positionStream;
  final MapController _mapController = MapController();
  List<LatLng> _agentLocations = [];

  @override
  void initState() {
    super.initState();
    _initializeFCM();
    _getCurrentLocation();
    _loadAgentLocations();
  }

  // Initialisation de Firebase Cloud Messaging (FCM)
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
      print("❌ Erreur d'initialisation FCM: $e");
    }
  }

  Future<void> _updateFCMToken([String? newToken]) async {
    try {
      String? token = newToken ?? await _firebaseMessaging.getToken();
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && token != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set(
          {'fcmToken': token},
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      print("❌ Erreur de mise à jour du token FCM: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      await Geolocator.requestPermission();
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _updateCurrentPosition(LatLng(position.latitude, position.longitude));
      _startLocationUpdates();
    } catch (e) {
      print("❌ Erreur de géolocalisation: $e");
    }
  }

  void _startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream(locationSettings: LocationSettings(accuracy: LocationAccuracy.high))
        .listen((Position position) {
      LatLng newPosition = LatLng(position.latitude, position.longitude);
      double distance = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );

      if (distance > 50) {
        _updateCurrentPosition(newPosition);
      }
    });
  }

  void _updateCurrentPosition(LatLng newPosition) {
    setState(() {
      _currentPosition = newPosition;
      _isLocationFetched = true;
    });
    _mapController.move(_currentPosition, 15.0);
    _updateAgentLocationInFirebase();
  }

  Future<void> _updateAgentLocationInFirebase() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set(
          {'latitude': _currentPosition.latitude, 'longitude': _currentPosition.longitude},
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      print("❌ Erreur de mise à jour Firestore: $e");
    }
  }

  Future<void> _loadAgentLocations() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();
      List<LatLng> locations = snapshot.docs.map((doc) {
        return LatLng(doc['latitude'], doc['longitude']);
      }).toList();
      setState(() => _agentLocations = locations);
    } catch (e) {
      print("❌ Erreur lors de la récupération des positions des agents: $e");
    }
  }

  Future<void> _getUserLocationOnClick() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _updateCurrentPosition(LatLng(position.latitude, position.longitude));
    } catch (e) {
      print("❌ Erreur lors de la récupération de la position de l'utilisateur: $e");
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carte Agent'),
        backgroundColor: Color(0xFFF40000),
        foregroundColor: Colors.white,
      ),
      drawer: _buildDrawer(context),
      body: _isLocationFetched ? _buildMap() : Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: _getUserLocationOnClick,
        child: Icon(Icons.my_location, color: Colors.white),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
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
              builder: (ctx) => Icon(Icons.location_on, color: Colors.red, size: 40.0),
            ),
            ..._agentLocations.map((latLng) => Marker(
              point: latLng,
              builder: (ctx) => Icon(Icons.location_on, color: Colors.blue, size: 30.0),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color:Color(0xFFF40000)),
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
    );
  }
}







