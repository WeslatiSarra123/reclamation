import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AgentReclamationsScreen extends StatefulWidget {
  @override
  _AgentReclamationsScreenState createState() => _AgentReclamationsScreenState();
}

class _AgentReclamationsScreenState extends State<AgentReclamationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer les réclamations de la base de données
  Stream<QuerySnapshot> _getReclamations() {
    return _firestore.collection('reclamations').where('status', isEqualTo: 'En attente').snapshots();
  }

  // Envoyer une notification push au client
  Future<void> _sendPushNotification(String clientToken, String status) async {
    try {
      await FirebaseMessaging.instance.sendMessage(
        to: clientToken, // Token FCM du client
        data: {
          'title': 'Statut de votre réclamation',
          'body': 'Votre réclamation a été $status par l\'agent.',
        },
      );
      print("Notification envoyée avec succès.");
    } catch (e) {
      print("Erreur lors de l'envoi de la notification: $e");
    }
  }

  // Mettre à jour le statut de la réclamation
  Future<void> _updateReclamationStatus(String reclamationId, String status, String clientToken) async {
    try {
      // Mettre à jour Firestore
      await _firestore.collection('reclamations').doc(reclamationId).update({
        'status': status,
        'resolutionDate': DateTime.now(),
      });

      // Envoyer la notification push au client
      await _sendPushNotification(clientToken, status);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Réclamation $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Réclamations en attente'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getReclamations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erreur de chargement des réclamations"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucune réclamation en attente'));
          }

          var reclamations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reclamations.length,
            itemBuilder: (context, index) {
              var reclamation = reclamations[index];
              return ListTile(
                title: Text('Transaction: ${reclamation['transactionType']}'),
                subtitle: Text('Numéro: ${reclamation['phoneNumber']}'),
                trailing: Text('Statut: ${reclamation['status']}'),
                onTap: () {
                  // Afficher une option pour accepter ou refuser la réclamation
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Gérer la réclamation'),
                        content: Text('Voulez-vous accepter ou refuser cette réclamation ?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              String clientToken = reclamation['clientToken']; // Récupérer le token du client
                              _updateReclamationStatus(reclamation.id, 'Acceptée', clientToken);
                              Navigator.pop(context); // Fermer le dialogue
                            },
                            child: Text('Accepter'),
                          ),
                          TextButton(
                            onPressed: () {
                              String clientToken = reclamation['clientToken']; // Récupérer le token du client
                              _updateReclamationStatus(reclamation.id, 'Refusée', clientToken);
                              Navigator.pop(context); // Fermer le dialogue
                            },
                            child: Text('Refuser'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
