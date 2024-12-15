import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MesReclamationsPage extends StatefulWidget {
  @override
  _MesReclamationsPageState createState() => _MesReclamationsPageState();
}

class _MesReclamationsPageState extends State<MesReclamationsPage> {
  String? clientId;

  @override
  void initState() {
    super.initState();
    _getClientId();
  }

  Future<void> _getClientId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        clientId = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (clientId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Mes Réclamations'),
          backgroundColor: Color(0xFFF40000),
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Réclamations'),
        backgroundColor: Color(0xFFF40000),
        foregroundColor: Colors.white, // Couleur de l'appbar
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reclamations')
            .where('clientId', isEqualTo: clientId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucune réclamation trouvée.'));
          }

          var reclamations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reclamations.length,
            itemBuilder: (context, index) {
              var reclamation = reclamations[index];
              String status = reclamation['status'];
              // Afficher le statut réel pour déboguer
              debugPrint('Statut de la réclamation: $status');
              return Card(
                margin: EdgeInsets.all(12),
                elevation: 5, // Ombre pour l'effet 3D
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Bords arrondis
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  leading: Icon(
                    Icons.report_problem, // Icône de réclamation
                    color: Colors.orange,
                    size: 40,
                  ),
                  title: Text(
                    'Transaction: ${reclamation['transactionType']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Date: ${reclamation['transactionDate']}',
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: _buildStatusBadge(status),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Détails de la réclamation'),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Type de transaction: ${reclamation['transactionType']}'),
                                Text('Date de la transaction: ${reclamation['transactionDate']}'),
                                Text('Numéro de téléphone: ${reclamation['phoneNumber']}'),
                                Text('Statut: ${reclamation['status']}'),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Fermer'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Fonction pour afficher un badge en fonction du statut
  Widget _buildStatusBadge(String status) {
    debugPrint('Statut récupéré pour le badge: $status'); // Vérification du statut récupéré

    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    String statusLowerCase = status.toLowerCase().trim();
    debugPrint('Statut normalisé: $statusLowerCase'); // Vérification du statut après normalisation

    switch (statusLowerCase) {
      case 'terminé':
        badgeColor = Colors.blue;
        badgeIcon = Icons.done_all;
        badgeText = 'Terminée';
        break;
      case 'en attente':
        badgeColor = Colors.orange;
        badgeIcon = Icons.hourglass_empty;
        badgeText = 'En Attente';
        break;
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.help;
        badgeText = 'Inconnu';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(badgeIcon, color: badgeColor),
        SizedBox(width: 8),
        Text(
          badgeText,
          style: TextStyle(
            color: badgeColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}


