import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionForm extends StatefulWidget {
  @override
  _TransactionFormState createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  String? _transactionDate;
  String? _transactionType;
  String? _phoneNumber;
  int? _errorCode;
  int? _orderStatus;
  double? _amount; // Nouvelle variable pour le montant
  bool _isSubmitting = false;

  // **Validation du numéro de téléphone**
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

  // **Sélection de la date de la transaction**
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2024, 12, 31),
    );

    if (selectedDate != null) {
      setState(() {
        _transactionDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
  }

  // **Soumission de la transaction**
  Future<void> _submitTransaction() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Définir le statut de la transaction basé sur errorCode et orderStatus
      String status = 'Rejected'; // Valeur par défaut
      if (_errorCode == 0 && _orderStatus == 2) {
        status = 'Approved';
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        // Ajouter la transaction dans Firestore
        await FirebaseFirestore.instance.collection('transactions').add({
          'transactionDate': _transactionDate,
          'transactionType': _transactionType,
          'phoneNumber': _phoneNumber,
          'errorCode': _errorCode,
          'orderStatus': _orderStatus,
          'amount': _amount, // Ajouter le montant ici
          'status': status, // Status basé sur errorCode et orderStatus
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction ajoutée avec succès !')),
        );

        Navigator.pop(context); // Ferme le formulaire après soumission
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout de la transaction : $e')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Formulaire de Transaction')),
        body: Padding(
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
                        validator: (value) => value == null || value.isEmpty ? 'La date de la transaction est requise' : null,
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
                      labelText: 'Code d\'erreur',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => _errorCode = int.tryParse(value ?? ''),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Statut de la commande',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => _orderStatus = int.tryParse(value ?? ''),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Montant',
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
                    onPressed: _isSubmitting ? null : _submitTransaction,
                    child: _isSubmitting ? CircularProgressIndicator(color: Colors.white) : Text('Envoyer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



