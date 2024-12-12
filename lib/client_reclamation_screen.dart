import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientReclamationsScreen extends StatefulWidget {
  @override
  _ClientReclamationsScreenState createState() => _ClientReclamationsScreenState();
}

class _ClientReclamationsScreenState extends State<ClientReclamationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer les réclamations du client
  Stream<QuerySnapshot> _getClientReclamations() {
    // Assurez-vous de filtrer par l'ID de l'utilisateur ou un autre identifiant unique
    return _firestore.collection('reclamations').where('clientId', isEqualTo: 'client-id').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Réclamations'),
        backgroundColor: Color(0xFFF40000),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getClientReclamations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erreur de chargement des réclamations"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucune réclamation en cours'));
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
                  // Afficher les détails de la réclamation ou une option pour la suivre
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Détails de la réclamation'),
                        content: Text('Statut actuel: ${reclamation['status']}'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Fermer'),
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

