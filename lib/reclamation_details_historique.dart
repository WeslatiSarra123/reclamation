import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReclamationDetailsHistoriqueScreen extends StatelessWidget {
  final QueryDocumentSnapshot reclamation;

  ReclamationDetailsHistoriqueScreen({required this.reclamation});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détails de la Réclamation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFFF40000),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                icon: Icons.email,
                title: 'Email du client',
                value: reclamation['clientEmail'],
              ),
              _buildInfoCard(
                icon: Icons.swap_horiz,
                title: 'Type de transaction',
                value: reclamation['transactionType'],
              ),
              _buildInfoCard(
                icon: Icons.phone,
                title: 'Numéro de téléphone',
                value: reclamation['phoneNumber'],
              ),
              _buildInfoCard(
                icon: Icons.calendar_today,
                title: 'Date de la transaction',
                value: reclamation['transactionDate'],
              ),
              _buildInfoCard(
                icon: Icons.info_outline,
                title: 'Statut',
                value: reclamation['status'],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget pour afficher les informations dans des cartes
  Widget _buildInfoCard({required IconData icon, required String title, required String value}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFF40000),
              child: Icon(icon, color: Colors.white),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFFF40000),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
