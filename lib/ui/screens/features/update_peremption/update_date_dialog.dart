import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:prestigeconsult/core/api/api_service.dart';
import 'package:prestigeconsult/models/product_search_result.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';

class UpdateDateDialog extends StatefulWidget {
  final ProductSearchResult product;

  const UpdateDateDialog({super.key, required this.product});

  @override
  State<UpdateDateDialog> createState() => _UpdateDateDialogState();
}

class _UpdateDateDialogState extends State<UpdateDateDialog> {
  final _dateController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _performUpdate() async {
    if (_dateController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Veuillez saisir ou choisir une date.");
      return;
    }

    DateTime newExpirationDate;
    try {
      // Dart attend MM/dd/yyyy, mais on affiche dd/MM/yyyy, donc on parse manuellement
      final parts = _dateController.text.split('/');
      if (parts.length != 3) throw const FormatException("Format de date invalide");
      newExpirationDate = DateTime.parse('${parts[2]}-${parts[1]}-${parts[0]}');
    } catch (e) {
      Fluttertoast.showToast(msg: "Format de date invalide. Utilisez JJ/MM/AAAA.");
      return;
    }

    setState(() => _isLoading = true);

    final dateFormatted = DateFormat('yyyy-MM-dd').format(newExpirationDate);
    final endpoint = '/fichearticle/dateperemption/${widget.product.id}/$dateFormatted';
    final configProvider = Provider.of<AppConfigProvider>(context, listen: false);

    try {
      final response = await _apiService.put(endpoint, configProvider, body: {});
      if (response != null && response['success'] == true) {
        Fluttertoast.showToast(
          msg: "${widget.product.name}\nDate mise à jour !",
          backgroundColor: Colors.green,
        );
        if (mounted) {
          Navigator.of(context).pop(true); // Pop avec un résultat de succès
        }
      } else {
        throw Exception("La réponse du serveur indique un échec.");
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Échec de la mise à jour: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Péremption actuelle: ${widget.product.datePeremption}'),
          const SizedBox(height: 20),
          TextField(
            controller: _dateController,
            keyboardType: TextInputType.datetime,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nouvelle date (JJ/MM/AAAA)',
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _selectDate,
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
              _DateInputFormatter(),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _performUpdate,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Valider'),
        ),
      ],
    );
  }
}

// Helper pour formater la date en JJ/MM/AAAA pendant la saisie
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.length > 8) return oldValue;

    var text = newValue.text.replaceAll('/', '');
    String newText = '';

    if (text.length >= 3) {
      newText = '${text.substring(0, 2)}/${text.substring(2)}';
    } else {
      newText = text;
    }
    if (text.length >= 5) {
      newText = '${text.substring(0, 2)}/${text.substring(2, 4)}/${text.substring(4)}';
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}