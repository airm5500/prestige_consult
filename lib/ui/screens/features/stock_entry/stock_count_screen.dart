import 'package:flutter/material.dart';
import 'package:prestigeconsult/models/delivery_slip.dart';
import 'package:prestigeconsult/models/delivery_slip_item.dart';
// Importer l'écran de rapport que nous créerons à la fin
import 'package:prestigeconsult/ui/screens/features/stock_entry/inventory_report_screen.dart';


class StockCountScreen extends StatefulWidget {
  final DeliverySlip deliverySlip;

  const StockCountScreen({super.key, required this.deliverySlip});

  @override
  State<StockCountScreen> createState() => _StockCountScreenState();
}

class _StockCountScreenState extends State<StockCountScreen> {
  final _searchController = TextEditingController();
  late final List<DeliverySlipItem> _items;

  // Maps pour gérer les contrôleurs et focus de chaque article
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, FocusNode> _quantityFocusNodes = {};

  @override
  void initState() {
    super.initState();
    _items = widget.deliverySlip.items;

    // Initialise un contrôleur et un focus node pour chaque article
    for (var item in _items) {
      _quantityControllers[item.id] = TextEditingController();
      _quantityFocusNodes[item.id] = FocusNode();
    }

    // Donne le focus au premier article de la liste au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_items.isNotEmpty) {
        _quantityFocusNodes[_items.first.id]?.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityControllers.values.forEach((controller) => controller.dispose());
    _quantityFocusNodes.values.forEach((node) => node.dispose());
    super.dispose();
  }

  void _onScanSubmitted(String cip) {
    if (cip.isEmpty) return;
    final index = _items.indexWhere((item) => item.produit.cip == cip);

    if (index != -1) {
      _quantityFocusNodes[_items[index].id]?.requestFocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produit non trouvé sur ce BL.'), backgroundColor: Colors.orange),
      );
    }
    _searchController.clear();
  }

  void _focusNext(int currentIndex) {
    if (currentIndex < _items.length - 1) {
      // Passe au champ suivant
      final nextItemId = _items[currentIndex + 1].id;
      _quantityFocusNodes[nextItemId]?.requestFocus();
    } else {
      // Si c'est le dernier champ, on retire le focus (ferme le clavier)
      _quantityFocusNodes[_items[currentIndex].id]?.unfocus();
    }
  }

  void _goToReport() {
    // Met à jour les quantités comptées dans la liste à partir des contrôleurs
    for (var item in _items) {
      final textValue = _quantityControllers[item.id]?.text ?? '0';
      item.quantiteComptee = int.tryParse(textValue) ?? 0;
    }

    // Navigue vers l'écran de rapport en passant la liste mise à jour
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventoryReportScreen(items: _items),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contrôle BL: ${widget.deliverySlip.referenceLivraison}'),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildItemsList()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
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
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
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
                decoration: const InputDecoration(
                  labelText: 'Compté',
                  border: OutlineInputBorder(),
                ),
                textInputAction: isLastItem ? TextInputAction.done : TextInputAction.next,
                onEditingComplete: () => _focusNext(index),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _goToReport,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const Text('Terminer & Voir le Rapport'),
      ),
    );
  }
}