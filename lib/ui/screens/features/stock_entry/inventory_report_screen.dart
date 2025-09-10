import 'package:flutter/material.dart';
import 'package:prestigeconsult/models/delivery_slip_item.dart';

class InventoryReportScreen extends StatelessWidget {
  final List<DeliverySlipItem> items;

  const InventoryReportScreen({super.key, required this.items});

  // Helper pour déterminer la couleur de la ligne en fonction de l'écart
  Color _getDiscrepancyColor(int discrepancy) {
    if (discrepancy < 0) {
      return Colors.red.shade100; // Moins compté que le stock théorique
    } else if (discrepancy > 0) {
      return Colors.orange.shade100; // Plus compté que le stock théorique
    }
    return Colors.transparent; // Correspondance exacte
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
    // Calculs pour la carte de résumé
    int totalTheoretical = items.fold(0, (sum, item) => sum + item.stockTheorique);
    int totalCounted = items.fold(0, (sum, item) => sum + item.quantiteComptee);
    int discrepancyLines = items.where((item) => item.stockTheorique != item.quantiteComptee).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapport d\'Inventaire'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildSummaryCard(totalTheoretical, totalCounted, discrepancyLines),
              const SizedBox(height: 16),
              _buildDataTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int theoretical, int counted, int linesWithIssues) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Stock Théorique', theoretical.toString()),
            _buildSummaryItem('Stock Compté', counted.toString()),
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
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Produit', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Théo.', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          DataColumn(label: Text('Compté', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          DataColumn(label: Text('Écart', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
        ],
        rows: items.map((item) {
          final discrepancy = item.quantiteComptee - item.stockTheorique;
          return DataRow(
            color: MaterialStateProperty.all(_getDiscrepancyColor(discrepancy)),
            cells: [
              DataCell(Text(item.produit.name)),
              DataCell(Text(item.stockTheorique.toString())),
              DataCell(Text(item.quantiteComptee.toString())),
              DataCell(Text(discrepancy.toString(), style: _getDiscrepancyTextStyle(discrepancy))),
            ],
          );
        }).toList(),
      ),
    );
  }
}