import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import FCM
import 'package:reclamation/agent_reclamation_screen.dart';

class AgentScreen extends StatefulWidget {
  @override
  _AgentScreenState createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance; // Initialize FCM
  LatLng _currentPosition = LatLng(12.9716, 77.5946); // Default position
  bool _isLocationFetched = false;
  bool _isLocationError = false;
  String _locationErrorMessage = '';
  StreamSubscription<Position>? _positionStream;
  final MapController _mapController = MapController();
  bool _isSatelliteView = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Get initial location
    _listenToLocationChanges(); // Listen for location changes
    _initializeFCM(); // Initialize FCM
  }

  // Initialize Firebase Cloud Messaging (FCM)
  void _initializeFCM() {
    _firebaseMessaging.requestPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print("Message received: ${message.notification!.title}");
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification opened: ${message.notification!.title}");
    });
  }

  // Function to get current location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocationError = true;
          _locationErrorMessage = "Location services are disabled.";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocationError = true;
          _locationErrorMessage = "Location permission is permanently denied.";
        });
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          setState(() {
            _isLocationError = true;
            _locationErrorMessage = "Location permission is denied.";
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

      await _updateAgentLocationInFirebase();
    } catch (e) {
      setState(() {
        _isLocationError = true;
        _locationErrorMessage = "Geolocation error: $e";
      });
    }
  }

  // Function to listen to location changes
  void _listenToLocationChanges() {
    _positionStream = Geolocator.getPositionStream(locationSettings: LocationSettings(
      accuracy: LocationAccuracy.high,
    )).listen((Position position) async {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      await _updateAgentLocationInFirebase();
    });
  }

  // Function to update agent location in Firebase
  Future<void> _updateAgentLocationInFirebase() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print("User is not logged in");
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
        'latitude': _currentPosition.latitude,
        'longitude': _currentPosition.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating location in Firebase: $e");
    }
  }

  // Function to send notification to the agent
  Future<void> _sendNotificationToAgent(String agentToken, String title, String body) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'token': agentToken,
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error sending notification to agent: $e");
    }
  }

  // Accept a reclamation
  void _acceptReclamation(String reclamationId, String clientToken) {
    FirebaseFirestore.instance.collection('reclamations').doc(reclamationId).update({
      'status': 'accepted',
    });

    _sendNotificationToClient(clientToken, 'Reclamation Accepted', 'Your reclamation has been accepted by an agent.');

    _sendNotificationToAgent(
      "agent_device_token", // Get the agent's device token
      'Reclamation Accepted',
      'You have accepted a reclamation.',
    );
  }

  // Function to notify the client
  Future<void> _sendNotificationToClient(String clientToken, String title, String body) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'token': clientToken,
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error sending notification to client: $e");
    }
  }

  // Logout function
  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      print("Logged out successfully");
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print("Error during logout: $e");
    }
  }

  // Function to get agent locations from Firebase
  Future<List<LatLng>> _getAgentLocations() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .get();

      List<LatLng> agentLocations = snapshot.docs.map((doc) {
        return LatLng(doc['latitude'], doc['longitude']);
      }).toList();

      return agentLocations;
    } catch (e) {
      print("Error retrieving agent locations: $e");
      return [];
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
        title: Text('Carte Agent '),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.red,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.assignment),
              title: Text('Reclamations'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AgentReclamationsScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Déconnexion'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: _isLocationFetched
          ? FutureBuilder<List<LatLng>>(
        future: _getAgentLocations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error retrieving agent locations.'));
          }

          List<LatLng> agentLocations = snapshot.data ?? [];

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentPosition,
              zoom: 15.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition,
                    builder: (ctx) => Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40.0,
                    ),
                  ),
                  ...agentLocations.map((latLng) => Marker(
                    point: latLng,
                    builder: (ctx) => Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 40.0,
                    ),
                  )),
                ],
              ),
            ],
          );
        },
      )
          : Center(
        child: _isLocationError
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: Colors.red, size: 50),
            SizedBox(height: 10),
            Text(
              _locationErrorMessage,
              style: TextStyle(color: Colors.red, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        )
            : CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController.move(_currentPosition, 15.0);
        },
        child: Icon(Icons.my_location),
        backgroundColor: Colors.blue,
      ),
    );
  }
}






