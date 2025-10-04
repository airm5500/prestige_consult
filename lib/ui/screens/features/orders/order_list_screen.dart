import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prestigeconsult/core/api/api_service.dart';
import 'package:prestigeconsult/core/logic/base_screen_logic.dart';
import 'package:prestigeconsult/models/order.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';
import 'package:prestigeconsult/ui/screens/features/orders/order_receiving_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with BaseScreenLogic {
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    // Utilise addPostFrameCallback pour s'assurer que le contexte est disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    final response = await runApiCall(() =>
        ApiService().get('/commande/list?page=1&start=0&limit=50', Provider.of<AppConfigProvider>(context, listen: false))
    );

    if (mounted && response != null && response['data'] is List) {
      final ordersData = response['data'] as List;
      setState(() {
        _orders = ordersData.map((json) => Order.fromJson(json)).toList();
        // Trie par date de création, du plus récent au plus ancien
        _orders.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Commandes'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
            ? const Center(child: Text('Aucune commande en cours.'))
            : ListView.builder(
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            final order = _orders[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(order.grossisteName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Réf: ${order.reference}\nDate: ${order.dateCreation}'),
                trailing: Chip(
                  label: Text('${order.productCount} produits'),
                  backgroundColor: Colors.blue.shade100,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderReceivingScreen(orderId: order.id),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}