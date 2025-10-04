import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prestigeconsult/core/api/api_service.dart';
import 'package:prestigeconsult/core/logic/base_screen_logic.dart';
import 'package:prestigeconsult/models/order_item.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';
import 'package:prestigeconsult/ui/screens/features/orders/order_summary_screen.dart';

class OrderReceivingScreen extends StatefulWidget {
  final String orderId;

  const OrderReceivingScreen({super.key, required this.orderId});

  @override
  State<OrderReceivingScreen> createState() => _OrderReceivingScreenState();
}

class _OrderReceivingScreenState extends State<OrderReceivingScreen> with BaseScreenLogic {
  final _apiService = ApiService();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  List<OrderItem> _orderItems = [];
  // Maps pour gérer les contrôleurs et focus de chaque ligne d'article
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, FocusNode> _quantityFocusNodes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (var node in _quantityFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOrderItems() async {
    final endpoint = '/commande/commande-en-cours-items?orderId=${widget.orderId}&limit=200';
    final response = await runApiCall(() =>
        _apiService.get(endpoint, Provider.of<AppConfigProvider>(context, listen: false))
    );

    if (mounted && response != null && response['data'] is List) {
      final itemsData = response['data'] as List;
      setState(() {
        _orderItems = itemsData.map((json) => OrderItem.fromJson(json)).toList();
        // Initialise un contrôleur et un focus node pour chaque article
        for (var item in _orderItems) {
          _quantityControllers[item.id] = TextEditingController();
          _quantityFocusNodes[item.id] = FocusNode();
        }
      });
    }
  }

  // Logique de scan/recherche
  void _onScanSubmitted(String cip) {
    if (cip.isEmpty) return;

    // Trouve l'article correspondant au CIP scanné
    final index = _orderItems.indexWhere((item) => item.productCip == cip);

    if (index != -1) {
      final item = _orderItems[index];
      // Demande le focus pour le champ de quantité de cet article
      _quantityFocusNodes[item.id]?.requestFocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit non trouvé dans cette commande.'), backgroundColor: Colors.red),
      );
    }
    _searchController.clear();
  }

  // Dans la méthode _goToSummary()

  void _goToSummary() {
    // Met à jour les quantités reçues dans la liste à partir des contrôleurs
    for (var item in _orderItems) {
      final textValue = _quantityControllers[item.id]?.text ?? '0';
      item.quantityReceived = int.tryParse(textValue) ?? 0;
    }

    // Naviguer vers l'écran de résumé en passant la liste _orderItems
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSummaryScreen(items: _orderItems),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réception Commande'),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orderItems.isEmpty
                ? const Center(child: Text('Aucun article dans cette commande.'))
                : _buildItemsList(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Scanner un produit (CIP)',
          prefixIcon: Icon(Icons.qr_code_scanner),
          border: OutlineInputBorder(),
        ),
        onSubmitted: _onScanSubmitted,
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      itemCount: _orderItems.length,
      itemBuilder: (context, index) {
        final item = _orderItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            title: Text(item.productName),
            subtitle: Text('CIP: ${item.productCip}'),
            trailing: SizedBox(
              width: 80,
              child: TextField(
                controller: _quantityControllers[item.id],
                focusNode: _quantityFocusNodes[item.id],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'Reçu',
                  border: OutlineInputBorder(),
                ),
                onEditingComplete: () {
                  // Quand l'utilisateur valide, on retourne au scan
                  _searchFocusNode.requestFocus();
                },
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
        onPressed: _goToSummary, //TODO: décommenter la navigation
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const Text('Terminer & Voir le Rapport'),
      ),
    );
  }
}