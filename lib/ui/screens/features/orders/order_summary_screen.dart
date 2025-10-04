import 'package:flutter/material.dart';
import 'package:prestigeconsult/models/order_item.dart';

class OrderSummaryScreen extends StatelessWidget {
  final List<OrderItem> items;

  const OrderSummaryScreen({super.key, required this.items});

  // Helper pour déterminer la couleur de la ligne en fonction de l'écart
  Color _getDiscrepancyColor(int discrepancy) {
    if (discrepancy < 0) {
      return Colors.red.shade100; // Moins reçu que commandé
    } else if (discrepancy > 0) {
      return Colors.orange.shade100; // Plus reçu que commandé
    }
    return Colors.transparent; // Quantité exacte
  }

  // Helper pour le style du texte de l'écart
  TextStyle _getDiscrepancyTextStyle(int discrepancy) {
    if (discrepancy < 0) {
      return const TextStyle(color: Colors.red, fontWeight: FontWeight.bold);
    } else if (discrepancy > 0) {
      return const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold);
    }
    return const TextStyle(color: Colors.green, fontWeight: FontWeight.bold);
  }

  @override
  Widget build(BuildContext context) {
    // Calculs pour le résumé
    int totalOrdered = items.fold(0, (sum, item) => sum + item.quantityOrdered);
    int totalReceived = items.fold(0, (sum, item) => sum + item.quantityReceived);
    int discrepancyLines = items.where((item) => item.quantityOrdered != item.quantityReceived).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapport de Réception'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildSummaryCard(totalOrdered, totalReceived, discrepancyLines),
              const SizedBox(height: 16),
              _buildDataTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int ordered, int received, int linesWithIssues) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Total Commandé', ordered.toString()),
            _buildSummaryItem('Total Reçu', received.toString()),
            _buildSummaryItem('Lignes en écart', linesWithIssues.toString(),
                color: linesWithIssues > 0 ? Colors.red : Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {Color color = Colors.black}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildDataTable() {
    return Card(
      elevation: 2,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Produit', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Cmd', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          DataColumn(label: Text('Reçu', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          DataColumn(label: Text('Écart', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        ],
        rows: items.map((item) {
          final discrepancy = item.quantityReceived - item.quantityOrdered;
          return DataRow(
            color: WidgetStateProperty.all(_getDiscrepancyColor(discrepancy)),
            cells: [
              DataCell(Text(item.productName)),
              DataCell(Text(item.quantityOrdered.toString())),
              DataCell(Text(item.quantityReceived.toString())),
              DataCell(Text(discrepancy.toString(), style: _getDiscrepancyTextStyle(discrepancy))),
            ],
          );
        }).toList(),
      ),
    );
  }
}