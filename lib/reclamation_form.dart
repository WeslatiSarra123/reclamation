import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReclamationForm extends StatefulWidget {
  final String agentId;
  final String clientId;

  ReclamationForm({required this.agentId, required this.clientId});

  @override
  _ReclamationFormState createState() => _ReclamationFormState();
}

class _ReclamationFormState extends State<ReclamationForm> {
  final _formKey = GlobalKey<FormState>();
  String? _transactionDate;
  String? _transactionType;
  String? _phoneNumber;
  double? _amount; // Nouveau champ pour le montant
  bool _isSubmitting = false;
  String? _clientEmail;

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
    final phoneRegex = RegExp(r'^[2-9]\d{7}$');
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
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2024, 12, 26),
    );

    if (selectedDate != null) {
      setState(() {
        _transactionDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
  }

  /// **Récupère l'email du client**
  Future<void> _fetchClientEmail() async {
    try {
      DocumentSnapshot clientSnapshot = await FirebaseFirestore.instance.collection('users').doc(widget.clientId).get();
      _clientEmail = clientSnapshot['email'];
    } catch (e) {
      print('Erreur lors de la récupération de l\'email du client : $e');
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
        await _fetchClientEmail();

        DocumentReference docRef = await FirebaseFirestore.instance.collection('reclamations').add({
          'agentId': widget.agentId,
          'clientId': widget.clientId,
          'clientEmail': _clientEmail,
          'transactionDate': _transactionDate,
          'transactionType': _transactionType,
          'phoneNumber': _phoneNumber,
          'amount': _amount, // Ajout du montant
          'status': 'En attente',
          'createdAt': Timestamp.now(),
        });

        await _sendNotificationToAgent(widget.agentId, docRef.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Réclamation envoyée avec succès !')),
        );

        Navigator.pop(context);
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

  Future<void> _sendNotificationToAgent(String agentId, String reclamationId) async {
    // Implémentation inchangée
  }

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
                  border: OutlineInputBorder(),
                ),
                validator: _validatePhone,
                onSaved: (value) => _phoneNumber = value,
              ),
              SizedBox(height: 10),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Montant(en dinar)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le montant est requis';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un montant valide';
                  }
                  return null;
                },
                onSaved: (value) => _amount = double.tryParse(value ?? ''),
              ),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReclamation,
                child: _isSubmitting ? CircularProgressIndicator(color: Colors.white) : Text('Envoyer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



