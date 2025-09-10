import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:prestigeconsult/core/api/api_service.dart';
import 'package:prestigeconsult/core/config/app_config.dart';
import 'package:prestigeconsult/models/article_evaluation.dart';
import 'package:prestigeconsult/models/order_history.dart';
import 'package:prestigeconsult/models/product_search_result.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';

// Pour simplifier, le graphique sera directement dans ce fichier
import 'package:fl_chart/fl_chart.dart';

class RechercheArticleDetailScreen extends StatefulWidget {
  final ProductSearchResult product;

  const RechercheArticleDetailScreen({super.key, required this.product});

  @override
  State<RechercheArticleDetailScreen> createState() => _RechercheArticleDetailScreenState();
}

class _RechercheArticleDetailScreenState extends State<RechercheArticleDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // State for Analysis Tab
  Future<Map<String, dynamic>>? _analysisDataFuture;
  final DateTime _startDate = DateTime(DateTime.now().year, 1, 1);
  final DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Charge les données pour l'onglet d'analyse
    _analysisDataFuture = _loadAnalysisData();
  }

  Future<Map<String, dynamic>> _loadAnalysisData() async {
    final api = ApiService();
    final config = Provider.of<AppConfigProvider>(context, listen: false);

    final dtStart = DateFormat('yyyy-MM-dd').format(_startDate);
    final dtEnd = DateFormat('yyyy-MM-dd').format(_endDate);

    // Lance les 2 appels API en parallèle
    final results = await Future.wait([
      // 1. Historique de commandes
      api.get('/commande/produit/commande/${widget.product.id}?search=&grossisteId=&dtStart=$dtStart&dtEnd=$dtEnd&page=1&start=0&limit=100&sort=[{"property":"dt_PEREMPTION","direction":"ASC"}]', config),
      // 2. Ventes annuelles (on prend l'année de fin de la période)
      api.get('/produit/stats/vente-annuelle?rayonId=&year=${_endDate.year}&search=${widget.product.cip}', config),
    ]);

    // Traitement des résultats
    final orderHistoryResponse = results[0];
    final salesResponse = results[1];

    final List<OrderHistory> orders = (orderHistoryResponse['data'] as List)
        .map((json) => OrderHistory.fromJson(json)).toList();

    ArticleEvaluation? sales;
    if (salesResponse['data'] is List && (salesResponse['data'] as List).isNotEmpty) {
      sales = ArticleEvaluation.fromJson(salesResponse['data'][0]);
    }

    return {'orders': orders, 'sales': sales};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Détails'),
            Tab(icon: Icon(Icons.analytics), text: 'Analyse'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildAnalysisTab(),
        ],
      ),
    );
  }

  // --- Onglet 1: DÉTAILS ---
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildDetailCard('Informations Principales', {
            'Code CIP': widget.product.cip,
            'Désignation': widget.product.name,
            'Prix Vente': '${widget.product.price} FCFA',
            'Prix Achat': '${widget.product.paf} FCFA',
            'EAN13': widget.product.ean13,
            'Emplacement': widget.product.emplacement,
          }),
          _buildDetailCard('Stock & Dates', {
            'Stock': widget.product.stock.toString(),
            'Date de Péremption': widget.product.datePeremption,
            'Quantité/Boîte': widget.product.quantiteDansBoite.toString(),
            'Date Création': widget.product.dateCreation,
            'Dernier Inventaire': widget.product.dateDernierInventaire,
            'Dernière Entrée': widget.product.dateDerniereEntree,
            'Dernière Vente': widget.product.dateDerniereVente,
          }),
          _buildDetailCard('État Actuel', {
            'En Commande': widget.product.produitState.enCommande.toString(),
            'En Suggestion': widget.product.produitState.enSuggestion.toString(),
            'Entrée': widget.product.produitState.entree.toString(),
          }),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, Map<String, String> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppStyles.titleStyle),
            const Divider(height: 20),
            ...data.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(e.value)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // --- Onglet 2: ANALYSE ---
  Widget _buildAnalysisTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _analysisDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Text('Erreur: ${snapshot.error ?? "Impossible de charger les données"}'));
        }

        final List<OrderHistory> orders = snapshot.data!['orders'];
        final ArticleEvaluation? sales = snapshot.data!['sales'];

        // --- Traitement des données pour le graphique ---
        final salesByMonth = sales?.monthlySales ?? {};
        final Map<int, int> ordersByMonth = {};

        for (var order in orders) {
          try {
            // Tente de parser la date d'entrée
            final entryDate = DateFormat('dd/MM/yyyy HH:mm').parse(order.dateEntree);
            ordersByMonth[entryDate.month] = (ordersByMonth[entryDate.month] ?? 0) + 1; // Fréquence
          } catch(e) {
            // Ignore les formats de date invalides
          }
        }

        return _buildChart(salesByMonth, ordersByMonth);
      },
    );
  }

  Widget _buildChart(Map<int, int> salesData, Map<int, int> orderFrequencyData) {
    List<LineChartBarData> lineBarsData = [];
    double maxY = 0;

    // Ligne pour les VENTES
    final salesSpots = <FlSpot>[];
    for (int month = 1; month <= 12; month++) {
      final quantity = (salesData[month] ?? 0).toDouble();
      if (quantity > maxY) maxY = quantity;
      salesSpots.add(FlSpot(month.toDouble(), quantity));
    }
    lineBarsData.add(LineChartBarData(
      spots: salesSpots,
      isCurved: true,
      color: Colors.blue,
      barWidth: 3,
      dotData: const FlDotData(show: true),
    ));

    // Ligne pour la FRÉQUENCE des commandes
    final orderSpots = <FlSpot>[];
    for (int month = 1; month <= 12; month++) {
      final frequency = (orderFrequencyData[month] ?? 0).toDouble();
      if (frequency > maxY) maxY = frequency;
      orderSpots.add(FlSpot(month.toDouble(), frequency));
    }
    lineBarsData.add(LineChartBarData(
      spots: orderSpots,
      isCurved: true,
      color: Colors.red,
      barWidth: 3,
      dotData: const FlDotData(show: true),
    ));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text('Évolution Ventes vs Fréquence Commandes (${_endDate.year})', style: AppStyles.titleStyle),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(Colors.blue, 'Ventes (Qté)'),
              _buildLegendItem(Colors.red, 'Commandes (Fréq.)'),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                maxY: maxY * 1.2,
                lineBarsData: lineBarsData,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (value, meta) => Text(DateFormat.MMM('fr_FR').format(DateTime(0, value.toInt()))))),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(children: [Container(width: 12, height: 12, color: color), const SizedBox(width: 8), Text(text)]);
  }
}