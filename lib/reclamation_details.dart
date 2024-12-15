import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:http/http.dart' as http;
import 'package:reclamation/constant.dart';
import 'dart:convert';

class ReclamationDetailsScreen extends StatelessWidget {
  final QueryDocumentSnapshot reclamation;
  ReclamationDetailsScreen({required this.reclamation});
  /// Fonction d'envoyer email
  Future<void> _sendConfirmationEmail(String reclamationId, String recipientEmail) async {
    // Récupérer la réclamation depuis la collection 'reclamations'
    DocumentSnapshot reclamationSnapshot = await FirebaseFirestore.instance.collection('reclamations').doc(reclamationId).get();

    if (!reclamationSnapshot.exists) {
      print('Réclamation non trouvée.');
      return;
    }

    /// Récupérer les données de la réclamation
    var reclamationData = reclamationSnapshot.data() as Map<String, dynamic>;
    String email = reclamationData['clientEmail'];
    String status = reclamationData['status'];
    String transactionDate = reclamationData['transactionDate'];
    String transactionType = reclamationData['transactionType'];
    String phoneNumber = reclamationData['phoneNumber'];

    // Créer le texte de l'email avec les informations de la réclamation
    String emailBody = 'Bonjour cher client ,  $email,\n\nSuite a votre reclamation; notre equipe ont verifié vos données et '
        'vous informe que votre reclamation : \n\n';
    emailBody += 'Date de transaction : $transactionDate \n';
    emailBody += 'Type de transaction : $transactionType \n';
    emailBody += 'Et numero de télephone  : $phoneNumber \n ';
    emailBody += 'est  : $status\n';
    emailBody += '\nNous vous remercions pour votre confiance.\n\nCordialement,\nVotre équipe Ooredoo.';

    String username = 'sarraweslati708@gmail.com'; // Votre adresse e-mail
    String password = 'cwzo nkle kuzl kpoz'; // Mot de passe de l'application ou de l'e-mail

    final smtpServer = gmail(username, password); // Utilisation du serveur SMTP Gmail
    final message = Message()
      ..from = Address(username, 'Reclamation Ooredoo')
      ..recipients.add(recipientEmail)
      ..subject = 'Information sur l\'état de votre réclamation'
      ..text = emailBody;

    try {
      final sendReport = await send(message, smtpServer); // Envoi de l'email
      print('Message envoyé: ${sendReport.toString()}');
    } on MailerException catch (e) {
      print('Erreur lors de l\'envoi de l\'e-mail: $e');
    }
  }
  /// Fonction pour mettre à jour le statut de la réclamation
  Future<void> _markAsResolved(BuildContext context) async {
    try {
      // Mettre à jour le champ 'status' de la réclamation à 'Terminé'
      await FirebaseFirestore.instance
          .collection('reclamations') // Nom de la collection
          .doc(reclamation.id) // Identifiant du document (réclamation)
          .update({'status': 'Terminé'}); // Mise à jour du statut

      // Afficher une notification de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut mis à jour avec succès à "Terminé" !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      // Appeler la fonction d'envoi d'email
      await _sendConfirmationEmail(reclamation.id, reclamation['clientEmail']);
      // Optionnel : revenir à l'écran précédent après la mise à jour
      Navigator.pop(context);

    } catch (e) {
      // Afficher une notification d'erreur en cas de problème
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour du statut.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  void _showResolutionForm(BuildContext context, var transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Formulaire de résolution'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${transaction['transactionDate']}'),
              SizedBox(height: 8),
            Text('Numero de telephone: ${transaction['phoneNumber']}'),
              SizedBox(height: 8),
              Text('Montant: ${transaction['amount']} TND'),
              SizedBox(height: 8),
              Text('Statut: ${transaction['status']}'),
              SizedBox(height: 8),
              Text('Type: ${transaction['transactionType']}'),
              SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Appeler la logique de paiement ici
            },
            child: Text('Payer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Annuler'),
          ),
        ],
      ),
    );
  }

  /// Fonction pour vérifier l'état de la transaction
  Future<void> _checkTransactionStatus(BuildContext context) async {
    try {
      final phoneNumber = reclamation['phoneNumber'];
      final transactionDate = reclamation['transactionDate'];
      final transactionType = reclamation['transactionType'];
      final amount = reclamation['amount'];

      // Rechercher la transaction dans Firestore
      QuerySnapshot transactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .where('transactionDate', isEqualTo: transactionDate)
          .where('transactionType', isEqualTo: transactionType)
          .where('amount', isEqualTo: amount)
          .get();

      if (transactionsSnapshot.docs.isEmpty) {
        // Aucune transaction trouvée
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aucune transaction trouvée pour cette réclamation.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Transaction trouvée
        var transaction = transactionsSnapshot.docs.first;
        String status = transaction['status'];  // Utilisation du champ 'status'
        // Vérifier l'état de la transaction
        if (status == 'Approved') {
          // Transaction approuvée
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('État de la transaction : approuvée, aucune problème.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          // Transaction rejetée
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('État de la transaction : rejetée, il y a un problème.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );

          // Afficher un bouton "Payer maintenant" si le statut est rejeté
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Problème de transaction'),
              content: Text('Il y a un problème avec cette transaction. Souhaitez-vous résoudre maintenant ?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showResolutionForm(context ,transaction);
                  },
                  child: Text('Résoudre maintenant'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Annuler'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la vérification de l\'état de la transaction.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
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
                icon: Icons.money,
                title: 'Montant de transaction',
                  value: reclamation['amount'].toString(),
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
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _checkTransactionStatus(context), // Vérification de l'état de la transaction
                  icon: Icon(Icons.history),
                  label: Text('Vérifier l\'État'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF40000),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _markAsResolved(context), // Appel de la fonction de mise à jour
                  icon: Icon(Icons.check_circle),
                  label: Text('Marquer comme Résolu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF40000),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  ),
                ),
              ),
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


