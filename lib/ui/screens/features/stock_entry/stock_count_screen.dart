import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prestigeconsult/models/delivery_slip.dart';
import 'package:prestigeconsult/models/delivery_slip_item.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';
import 'package:prestigeconsult/ui/screens/features/stock_entry/inventory_report_screen.dart';

class StockCountScreen extends StatefulWidget {
  final DeliverySlip deliverySlip;
  final bool isAlreadyControlled;

  const StockCountScreen({
    super.key,
    required this.deliverySlip,
    required this.isAlreadyControlled,
  });

  @override
  State<StockCountScreen> createState() => _StockCountScreenState();
}

class _StockCountScreenState extends State<StockCountScreen> {
  final _searchController = TextEditingController();
  late final List<DeliverySlipItem> _items;
  bool _isEditMode = false;

  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, FocusNode> _quantityFocusNodes = {};

  @override
  void initState() {
    super.initState();
    _items = widget.deliverySlip.items;
    _isEditMode = !widget.isAlreadyControlled;

    for (var item in _items) {
      _quantityControllers[item.id] = TextEditingController();
      _quantityFocusNodes[item.id] = FocusNode();
    }

    if (widget.isAlreadyControlled) {
      _loadSavedCounts();
    } else if (_items.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _quantityFocusNodes[_items.first.id]?.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (var node in _quantityFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSavedCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDataString = prefs.getString('control_${widget.deliverySlip.id}');
    if (savedDataString != null) {
      final savedCounts = Map<String, int>.from(json.decode(savedDataString));
      for (var item in _items) {
        _quantityControllers[item.id]?.text = (savedCounts[item.id] ?? 0).toString();
      }
    }
  }

  Future<void> _saveAndGoToReport() async {
    final prefs = await SharedPreferences.getInstance();
    final countsToSave = <String, int>{};
    for (var item in _items) {
      final textValue = _quantityControllers[item.id]?.text ?? '0';
      item.quantiteComptee = int.tryParse(textValue) ?? 0;
      countsToSave[item.id] = item.quantiteComptee;
    }
    await prefs.setString('control_${widget.deliverySlip.id}', json.encode(countsToSave));

    final controlledIds = prefs.getStringList('controlled_slip_ids') ?? [];
    if (!controlledIds.contains(widget.deliverySlip.id)) {
      controlledIds.add(widget.deliverySlip.id);
      await prefs.setStringList('controlled_slip_ids', controlledIds);
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InventoryReportScreen(
            items: _items,
            slip: widget.deliverySlip,
          ),
        ),
      );
    }
  }

  void _onScanSubmitted(String cip) {
    if (cip.isEmpty) return;
    final index = _items.indexWhere((item) => item.produit.cip == cip);

    if (index != -1) {
      _quantityFocusNodes[_items[index].id]?.requestFocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit non trouvé sur ce BL.'), backgroundColor: Colors.orange),
      );
    }
    _searchController.clear();
  }

  void _focusNext(int currentIndex) {
    if (currentIndex < _items.length - 1) {
      final nextItemId = _items[currentIndex + 1].id;
      _quantityFocusNodes[nextItemId]?.requestFocus();
    } else {
      _quantityFocusNodes[_items[currentIndex].id]?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canModify = Provider.of<AppConfigProvider>(context).allowControlModification;

    return Scaffold(
      appBar: AppBar(
        title: Text('Contrôle BL: ${widget.deliverySlip.referenceLivraison}'),
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Modifier le contrôle',
              onPressed: canModify
                  ? () {
                setState(() {
                  _isEditMode = true;
                  if (_items.isNotEmpty) {
                    _quantityFocusNodes[_items.first.id]?.requestFocus();
                  }
                });
              }
                  : null,
            ),
        ],
      ),
      body: Column(
        children: [
          // --- Contenu de _buildSearchBar ---
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Scanner pour sauter à un produit',
                prefixIcon: Icon(Icons.qr_code_scanner),
                border: OutlineInputBorder(),
              ),
              onSubmitted: _onScanSubmitted,
            ),
          ),
          // --- Contenu de _buildItemsList ---
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isLastItem = index == _items.length - 1;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    title: Text(item.produit.name),
                    subtitle: Text('CIP: ${item.produit.cip}'),
                    trailing: SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _quantityControllers[item.id],
                        focusNode: _quantityFocusNodes[item.id],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        enabled: _isEditMode,
                        decoration: InputDecoration(
                          labelText: 'Compté',
                          border: const OutlineInputBorder(),
                          filled: !_isEditMode,
                          fillColor: Colors.grey[200],
                        ),
                        textInputAction: isLastItem ? TextInputAction.done : TextInputAction.next,
                        onEditingComplete: () => _focusNext(index),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // --- Contenu de _buildFooter ---
          if (_isEditMode)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _saveAndGoToReport,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Terminer & Voir le Rapport'),
              ),
            ),
        ],
      ),
    );
  }
}