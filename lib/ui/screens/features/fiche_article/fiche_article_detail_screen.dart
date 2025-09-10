import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prestigeconsult/core/config/app_config.dart';
import 'package:prestigeconsult/models/article_detail.dart';

class FicheArticleDetailScreen extends StatelessWidget {
  final ArticleDetail article;

  const FicheArticleDetailScreen({super.key, required this.article});

  // Helper pour afficher une ligne de détail (label + valeur)
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppStyles.dataLabelStyle),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: AppStyles.dataValueStyle)),
        ],
      ),
    );
  }

  // Affiche la modale avec le graphique
  void _showComparisonChart(BuildContext context) {
    final now = DateTime.now();
    final salesData = article.salesByMonth;
    final List<Map<String, dynamic>> lastThreeMonthsData = [];

    for (int i = 0; i < 3; i++) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthNumber = monthDate.month;
      final monthName = DateFormat.MMM('fr_FR').format(monthDate);

      lastThreeMonthsData.add({
        'month': monthNumber,
        'name': monthName,
        'quantity': salesData[monthNumber] ?? 0,
      });
    }

    final chartData = lastThreeMonthsData.reversed.toList();
    final hasData = chartData.any((d) => d['quantity'] > 0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ventes des 3 derniers mois'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: hasData
              ? _buildChart(chartData)
          // ignore: prefer_const_constructors
              : Center(child: Text("Aucune donnée de vente pour la période sélectionnée.")),
        ),
        actions: [
          TextButton(
            child: const Text('Fermer'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // Construit le widget BarChart
  Widget _buildChart(List<Map<String, dynamic>> chartData) {
    final List<Color> barColors = [Colors.blue, Colors.green, Colors.orange];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (chartData.map((d) => d['quantity'] as int).reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            // LA LIGNE POSANT PROBLÈME A ÉTÉ SUPPRIMÉE ICI
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${chartData[groupIndex]['name']}\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: [TextSpan(text: rod.toY.round().toString(), style: const TextStyle(color: Colors.yellow))],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4.0,
                  child: Text(chartData[value.toInt()]['name']),
                );
              },
              reservedSize: 28,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        barGroups: List.generate(chartData.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: chartData[index]['quantity'].toDouble(),
                color: barColors[index % barColors.length],
                width: 22,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article.libelle, overflow: TextOverflow.ellipsis),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow('CIP:', article.codeCip),
                    _buildDetailRow('Désignation:', article.libelle),
                    _buildDetailRow('Prix Achat:', '${article.prixAchat.toStringAsFixed(0)} FCFA'),
                    _buildDetailRow('Prix Vente:', '${article.prixVente.toStringAsFixed(0)} FCFA'),
                    _buildDetailRow('Grossiste:', article.grossiste),
                    _buildDetailRow('Moyenne:', article.moyenne.toStringAsFixed(2)),
                    _buildDetailRow('Emplacement:', article.emplacement),
                    _buildDetailRow('Qté totale vendue:', article.quantiteVendue.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Consommation par mois:', style: AppStyles.titleStyle),
                    const SizedBox(height: 10),
                    if (article.formattedMonthlySales.isNotEmpty)
                      ...article.formattedMonthlySales.map((sale) => Text(sale, style: AppStyles.dataValueStyle)),
                    if (article.formattedMonthlySales.isEmpty)
                      const Text("Aucune donnée de vente mensuelle.", style: AppStyles.dataValueStyle),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.bar_chart),
              label: const Text('Comparer les 3 derniers mois'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
              onPressed: () => _showComparisonChart(context),
            ),
          ],
        ),
      ),
    );
  }
}