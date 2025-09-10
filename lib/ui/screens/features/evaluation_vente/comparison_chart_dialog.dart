import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:prestigeconsult/core/api/api_service.dart';
import 'package:prestigeconsult/models/article_evaluation.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';

class ComparisonChartDialog extends StatefulWidget {
  final String articleCip;
  final ApiService apiService;
  final AppConfigProvider configProvider;

  const ComparisonChartDialog({
    super.key,
    required this.articleCip,
    required this.apiService,
    required this.configProvider,
  });

  @override
  State<ComparisonChartDialog> createState() => _ComparisonChartDialogState();
}

class _ComparisonChartDialogState extends State<ComparisonChartDialog> {
  Future<List<ArticleEvaluation?>>? _chartDataFuture;

  @override
  void initState() {
    super.initState();
    _chartDataFuture = _loadThreeYearsData();
  }

  Future<List<ArticleEvaluation?>> _loadThreeYearsData() async {
    final currentYear = DateTime.now().year;
    final years = [currentYear, currentYear - 1, currentYear - 2];

    // Exécute les 3 appels API en parallèle pour de meilleures performances
    final results = await Future.wait(years.map((year) async {
      final endpoint = '/produit/stats/vente-annuelle?rayonId=&year=$year&search=${widget.articleCip}';
      try {
        final response = await widget.apiService.get(endpoint, widget.configProvider);
        if (response != null && response['data'] is List && response['data'].isNotEmpty) {
          return ArticleEvaluation.fromJson(response['data'][0]);
        }
      } catch (e) {
        // Ignore errors for individual years, they'll be treated as no data
      }
      return null;
    }));

    return results;
  }

  // Construit le graphique
  Widget _buildChart(List<ArticleEvaluation?> data) {
    final List<Color> lineColors = [Colors.blue, Colors.green, Colors.red];
    final List<LineChartBarData> lineBarsData = [];

    double maxY = 0; // Pour ajuster l'échelle du graphique

    for (int i = 0; i < data.length; i++) {
      final yearData = data[i];
      if (yearData == null) continue;

      final spots = <FlSpot>[];
      for (int month = 1; month <= 12; month++) {
        final quantity = (yearData.monthlySales[month] ?? 0).toDouble();
        if (quantity > maxY) maxY = quantity;
        spots.add(FlSpot(month.toDouble(), quantity));
      }

      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: lineColors[i],
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    if (lineBarsData.isEmpty) {
      return const Center(child: Text("Aucune donnée de vente trouvée pour les 3 dernières années."));
    }

    return Column(
      children: [
        _buildLegend(data), // Affiche la légende
        const SizedBox(height: 16),
        Expanded(
          child: LineChart(
            LineChartData(
              maxY: maxY * 1.2, // Marge de 20%
              lineBarsData: lineBarsData,
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final month = DateFormat.MMM('fr_FR').format(DateTime(0, value.toInt()));
                      return Text(month, style: const TextStyle(fontSize: 10));
                    },
                    interval: 1,
                  ),
                ),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: true),
            ),
          ),
        ),
      ],
    );
  }

  // Affiche la légende des couleurs/années
  Widget _buildLegend(List<ArticleEvaluation?> data) {
    final List<Color> lineColors = [Colors.blue, Colors.green, Colors.red];
    List<Widget> legends = [];
    int currentYear = DateTime.now().year;

    for(int i = 0; i < data.length; i++){
      if(data[i] != null){ // Affiche la légende seulement si l'année a des données
        legends.add(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, color: lineColors[i]),
                const SizedBox(width: 4),
                Text('${currentYear - i}'),
              ],
            )
        );
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: legends,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Comparaison Annuelle'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: FutureBuilder<List<ArticleEvaluation?>>(
          future: _chartDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("Erreur lors du chargement des données."));
            }
            return _buildChart(snapshot.data!);
          },
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Fermer'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}