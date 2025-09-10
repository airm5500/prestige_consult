import 'package:flutter/material.dart';
import 'package:prestigeconsult/models/delivery_slip.dart';
import 'package:prestigeconsult/models/delivery_slip_item.dart';

class InventoryReportScreen extends StatelessWidget {
  final List<DeliverySlipItem> items;
  final DeliverySlip slip;

  const InventoryReportScreen({
    super.key,
    required this.items,
    required this.slip
  });

  @override
  Widget build(BuildContext context) {
    // --- Fonctions Helper déplacées ici pour plus de clarté ---
    Color getDiscrepancyColor(int discrepancy) {
      if (discrepancy < 0) return Colors.red.shade100;
      if (discrepancy > 0) return Colors.orange.shade100;
      return Colors.transparent;
    }

    TextStyle getDiscrepancyTextStyle(int discrepancy) {
      if (discrepancy < 0) return const TextStyle(color: Colors.red, fontWeight: FontWeight.bold);
      if (discrepancy > 0) return const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold);
      return const TextStyle(color: Colors.green, fontWeight: FontWeight.bold);
    }
    // --- Fin des fonctions Helper ---

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
              // --- Contenu de _buildSummaryCard ---
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                          'Contrôle effectué par : ${slip.userName}',
                          style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(totalTheoretical.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const Text('Stock Théorique', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          Column(
                            children: [
                              Text(totalCounted.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const Text('Stock Compté', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          Column(
                            children: [
                              Text(discrepancyLines.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: discrepancyLines > 0 ? Colors.red : Colors.green)),
                              const Text('Lignes en écart', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // --- Contenu de _buildDataTable ---
              Card(
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
                      color: WidgetStateProperty.all(getDiscrepancyColor(discrepancy)),
                      cells: [
                        DataCell(Text(item.produit.name)),
                        DataCell(Text(item.stockTheorique.toString())),
                        DataCell(Text(item.quantiteComptee.toString())),
                        DataCell(Text(discrepancy.toString(), style: getDiscrepancyTextStyle(discrepancy))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}