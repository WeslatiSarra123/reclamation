import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:http/http.dart' as http;
import 'package:reclamation/constant.dart';
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:mailer/mailer.dart' as mailer_address;
import 'package:flutter/material.dart' as material;
class ReclamationDetailsScreen extends StatefulWidget {
  late final QueryDocumentSnapshot reclamation;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  // Constructor to accept the reclamation
  ReclamationDetailsScreen({required this.reclamation});

  @override
  _ReclamationDetailsScreenState createState() => _ReclamationDetailsScreenState();
}

class _ReclamationDetailsScreenState extends State<ReclamationDetailsScreen> {
  late final QueryDocumentSnapshot reclamation;

  // Initialize the reclamation in the initState method
  @override
  void initState() {
    super.initState();
    reclamation = widget.reclamation;
  }
  /// Fonction d'envoyer email
  Future<void> _sendConfirmationEmail(String reclamationId, String recipientEmail) async {
    try {
      DocumentSnapshot reclamationSnapshot = await FirebaseFirestore.instance.collection('reclamations').doc(reclamationId).get();

      if (!reclamationSnapshot.exists) {
        print('Réclamation non trouvée.');
        return;
      }
      var reclamationData = reclamationSnapshot.data() as Map<String, dynamic>;
      String email = reclamationData['clientEmail'];
      String status = reclamationData['status'];
      String transactionDate = reclamationData['transactionDate'];
      String transactionType = reclamationData['transactionType'];
      String phoneNumber = reclamationData['phoneNumber'];

      String emailBody = 'Bonjour cher client, $email,\n\nSuite à votre réclamation, notre équipe a vérifié vos données et '
          'vous informe que votre réclamation : \n\n';
      emailBody += 'Date de la transaction : $transactionDate \n';
      emailBody += 'Type de la transaction : $transactionType \n';
      emailBody += 'Numéro de téléphone : $phoneNumber \n';
      emailBody += 'Statut : $status\n';
      emailBody += '\nNous vous remercions pour votre confiance.\n\nCordialement,\nL\'équipe Ooredoo.';

      String username = 'sarraweslati708@gmail.com'; // Adresse e-mail
      String password = 'cwzo nkle kuzl kpoz'; // Mot de passe de l'application ou du compte

      final smtpServer = gmail(username, password);
      final message = Message()
        ..from = mailer_address.Address(username, 'Reclamation Ooredoo')
        ..recipients.add(recipientEmail)
        ..subject = 'Information sur l\'état de votre réclamation'
        ..text = emailBody;

      await send(message, smtpServer);
      print('Message envoyé avec succès.');
    } catch (e) {
      print('Erreur lors de l\'envoi de l\'e-mail : $e');
    }
  }

  /// Fonction pour mettre à jour le statut de la réclamation
  Future<void> _markAsResolved() async {
    try {
      await FirebaseFirestore.instance.collection('reclamations').doc(reclamation.id).update({'status': 'Terminé'});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut mis à jour à "Terminé" !'),
          backgroundColor: Colors.green,
        ),
      );

      await _sendConfirmationEmail(reclamation.id, reclamation['clientEmail']);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour du statut.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  ///make paiement
  Future<void> makePayment( double amount, var transaction) async {
    try {
      var paymentIntent = await createPaymentIntent((amount * 100).toStringAsFixed(0), 'usd');
      //Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntent['client_secret'],
            style: ThemeMode.dark,
            merchantDisplayName: 'Adnan'
        ),
      ).then((value) {});

      displayPaymentSheet(transaction);
    } catch (e, s) {
      print('Error in payment: $e$s');
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent(String amount, String currency) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $SECRET_KEY', // Remplacer SECRET_KEY par votre clé secrète Stripe
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amount,
          'currency': currency,
        },
      );
      return json.decode(response.body);
    } catch (e) {
      rethrow;
    }
  }
  displayPaymentSheet(var transaction) async {
    try {
      await Stripe.instance.presentPaymentSheet();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Paiement réussi"), backgroundColor: Colors.green),
        );

        // Mettre à jour la transaction dans Firestore (ou votre base de données)
        try {
          await FirebaseFirestore.instance.collection('transactions').doc(transaction.id).update({'errorCode': 0, 'orderStatus': 2, 'status': 'Approved'});
          print("Transaction mise à jour avec succès dans Firestore");
          if (transaction['errorCode'] == 0 &&
              transaction['orderStatus'] == 2 &&
              transaction['status'] == 'Approved') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Transaction résolue avec succès"), backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          print("Erreur lors de la mise à jour de Firestore: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erreur lors de la mise à jour de la transaction"), backgroundColor: Colors.red),
            );
          }
        }
      }
    } on StripeException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de paiement"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print("Erreur non Stripe: $e");
    }
  }

  void _showResolutionForm( var transaction) {
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
            onPressed: () async {
              Navigator.pop(context);
              double amount = transaction['amount'] is String
                  ? double.parse(transaction['amount']) // Convert string to double if it's a string
                  : transaction['amount']; // Use directly if it's already a double
              await makePayment(amount, transaction);
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
  Future<void> _checkTransactionStatus() async {
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
                    _showResolutionForm(transaction);
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
      key: widget.scaffoldMessengerKey,
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
                  onPressed: () => _checkTransactionStatus(), // Vérification de l'état de la transaction
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
                  onPressed: () => _markAsResolved(), // Appel de la fonction de mise à jour
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
    return material.Card(
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


