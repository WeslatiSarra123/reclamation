import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReclamationForm extends StatefulWidget {
  final String agentId; // L'ID de l'agent auquel la réclamation sera associée

  ReclamationForm({required this.agentId}); // Le constructeur pour initialiser l'ID de l'agent

  @override
  _ReclamationFormState createState() => _ReclamationFormState();
}

class _ReclamationFormState extends State<ReclamationForm> {
  final _formKey = GlobalKey<FormState>(); // Clé de formulaire pour la validation
  String? _transactionDate; // La date de la transaction saisie par l'utilisateur
  String? _transactionType; // Le type de transaction (Recharge, Forfait, Facture)
  String? _phoneNumber; // Le numéro de téléphone de l'utilisateur
  bool _isSubmitting = false; // Indique si le formulaire est en cours de soumission

  /// **Validation de la date de transaction**
  String? _validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'La date de la transaction est requise';
    }
    return null;
  }

  /// **Validation du numéro de téléphone**
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    final phoneRegex = RegExp(r'^\d{8}$'); // Regex pour les numéros tunisiens
    if (!phoneRegex.hasMatch(value)) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  /// **Affiche le sélecteur de date**
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null) {
      setState(() {
        _transactionDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
  }

  /// **Soumission de la réclamation**
  Future<void> _submitReclamation() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isSubmitting = true;
      });

      try {
        // **AJOUT : Enregistrement de la réclamation dans Firestore**
        DocumentReference docRef = await FirebaseFirestore.instance.collection('reclamations').add({
          'agentId': widget.agentId, // L'ID de l'agent associé
          'transactionDate': _transactionDate, // La date de la transaction
          'transactionType': _transactionType, // Le type de transaction
          'phoneNumber': _phoneNumber, // Numéro de téléphone du client
          'status': 'En attente', // Statut initial de la réclamation
          'createdAt': Timestamp.now(), // Date et heure de création
        });

        // **AJOUT : Envoi de la notification à l'agent**
        await _sendNotificationToAgent(widget.agentId, docRef.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Réclamation envoyée avec succès !')),
        );

        Navigator.pop(context); // Ferme la modale après la soumission
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi de la réclamation : $e')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// **ENVOI DE LA NOTIFICATION À L'AGENT**
  /// - Récupère le jeton FCM de l'agent
  /// - Ajoute la notification dans la collection `notifications`
  Future<void> _sendNotificationToAgent(String agentId, String reclamationId) async {
    try {
      // **AJOUT : Récupération du jeton FCM de l'agent**
      DocumentSnapshot agentSnapshot = await FirebaseFirestore.instance.collection('users').doc(agentId).get();
      String? agentFcmToken = agentSnapshot['fcmToken']; // Le jeton FCM de l'agent doit être enregistré

      if (agentFcmToken != null) {
        // **AJOUT : Envoi de la notification à l'agent**
        await FirebaseFirestore.instance.collection('notifications').add({
          'to': agentFcmToken, // Jeton FCM de l'agent
          'title': 'Nouvelle réclamation', // Titre de la notification
          'body': 'Un client a envoyé une réclamation.', // Corps du message
          'reclamationId': reclamationId, // Identifiant de la réclamation
          'createdAt': Timestamp.now(), // Date et heure de la création
        });
      }
    } catch (e) {
      print('Erreur lors de l\'envoi de la notification : $e');
    }
  }

  /// **Interface utilisateur**
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Date de la transaction',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: _transactionDate),
                    validator: _validateDate,
                    onSaved: (value) => _transactionDate = value,
                  ),
                ),
              ),
              SizedBox(height: 10),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Type de transaction',
                  border: OutlineInputBorder(),
                ),
                items: ['Recharge', 'Forfait', 'Facture'].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) => _transactionType = value,
                validator: (value) => value == null ? 'Veuillez sélectionner un type' : null,
              ),
              SizedBox(height: 10),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: '8 chiffres',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
                onSaved: (value) => _phoneNumber = value,
              ),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReclamation,
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Envoyer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


