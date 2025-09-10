import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prestigeconsult/core/api/api_service.dart';
import 'package:prestigeconsult/core/logic/base_screen_logic.dart';
import 'package:prestigeconsult/models/article_detail.dart'; // On réutilise ce modèle
import 'package:prestigeconsult/models/article_evaluation.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';
import 'package:prestigeconsult/ui/screens/features/evaluation_vente/comparison_chart_dialog.dart';
import 'package:intl/intl.dart';

class EvaluationVenteScreen extends StatefulWidget {
  const EvaluationVenteScreen({super.key});

  @override
  State<EvaluationVenteScreen> createState() => _EvaluationVenteScreenState();
}

class _EvaluationVenteScreenState extends State<EvaluationVenteScreen> with BaseScreenLogic {
  // --- State Variables ---
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<ArticleDetail> _searchResults = [];
  ArticleDetail? _selectedArticle;
  ArticleEvaluation? _annualSalesData;

  int _selectedYear = DateTime.now().year;
  bool _isLoadingDetails = false;

  final ApiService _apiService = ApiService();

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // --- Logic Methods ---
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _performSearch);
  }

  Future<void> _performSearch() async {
    // Reset state on new search
    setState(() {
      _selectedArticle = null;
      _annualSalesData = null;
    });

    final query = _searchController.text.trim();
    final isNumeric = int.tryParse(query) != null;
    if (query.isEmpty || (isNumeric && query.length < 3) || (!isNumeric && query.length < 2)) {
      setState(() => _searchResults = []);
      return;
    }

    final response = await runApiCall(() => _apiService.get('/info?search=$query', Provider.of<AppConfigProvider>(context, listen: false)));
    if (response != null && response is List) {
      setState(() {
        _searchResults = response.map((json) => ArticleDetail.fromJson(json)).toList();
      });
    }
  }

  Future<void> _onArticleSelected(ArticleDetail article) async {
    setState(() {
      _selectedArticle = article;
      _searchResults = []; // Hide search results
      _isLoadingDetails = true;
    });
    await _loadAnnualSalesForYear(_selectedYear);
    setState(() {
      _isLoadingDetails = false;
    });
  }

  Future<void> _loadAnnualSalesForYear(int year) async {
    if (_selectedArticle == null) return;

    final endpoint = '/produit/stats/vente-annuelle?rayonId=&year=$year&search=${_selectedArticle!.codeCip}';
    final response = await runApiCall(() => _apiService.get(endpoint, Provider.of<AppConfigProvider>(context, listen: false)));

    if (response != null && response['data'] is List && response['data'].isNotEmpty) {
      setState(() {
        _annualSalesData = ArticleEvaluation.fromJson(response['data'][0]);
      });
    } else {
      setState(() {
        _annualSalesData = null; // No data for this year
      });
    }
  }

  void _showComparisonChart() {
    if (_selectedArticle == null) return;
    showDialog(
      context: context,
      builder: (_) => ComparisonChartDialog(
        articleCip: _selectedArticle!.codeCip,
        apiService: _apiService,
        configProvider: Provider.of<AppConfigProvider>(context, listen: false),
      ),
    );
  }

  void _resetSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _selectedArticle = null;
      _annualSalesData = null;
    });
  }

  // --- Build Methods ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Évaluation des Ventes')),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _selectedArticle == null
                ? _buildSearchBody()
                : _buildDetailsBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un article...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _resetSearch,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBody() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (_searchResults.isEmpty) return const Center(child: Text('Veuillez rechercher un article.'));

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final article = _searchResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            title: Text(article.libelle),
            subtitle: Text('CIP: ${article.codeCip}'),
            onTap: () => _onArticleSelected(article),
          ),
        );
      },
    );
  }

  Widget _buildDetailsBody() {
    // La correction est ici : on sépare la création de la liste et le tri.
    final sortedMonths = _annualSalesData?.monthlySales.keys.toList() ?? [];
    sortedMonths.sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedArticle!.libelle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  Text('CIP: ${_selectedArticle!.codeCip}'),
                  Text('PRIX VENTE: ${_selectedArticle!.prixVente.toStringAsFixed(0)} FCFA'),
                  Text('EMPLACEMENT: ${_selectedArticle!.emplacement}'),
                  Text('GROSSISTE: ${_selectedArticle!.grossiste}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildYearSelector(),
                  const Divider(height: 20),
                  if (_isLoadingDetails)
                    const CircularProgressIndicator()
                  else if (_annualSalesData == null)
                    Text('Aucune donnée de vente pour l\'année $_selectedYear.')
                  else
                  // Ici on utilise la liste triée
                    ...sortedMonths.map((month) {
                      final monthName = DateFormat.MMMM('fr_FR').format(DateTime(0, month));
                      final quantity = _annualSalesData!.monthlySales[month];
                      return ListTile(
                        title: Text(monthName[0].toUpperCase() + monthName.substring(1)),
                        trailing: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.stacked_line_chart),
            label: const Text('Comparer les 3 dernières années'),
            onPressed: _showComparisonChart,
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    int currentYear = DateTime.now().year;
    List<int> years = List.generate(5, (index) => currentYear - index); // Les 5 dernières années

    return DropdownButtonFormField<int>(
      initialValue: _selectedYear,
      decoration: const InputDecoration(labelText: 'Année'),
      items: years.map((year) {
        return DropdownMenuItem<int>(value: year, child: Text(year.toString()));
      }).toList(),
      onChanged: (year) {
        if (year != null) {
          setState(() {
            _selectedYear = year;
            _isLoadingDetails = true;
          });
          _loadAnnualSalesForYear(year).then((_) {
            setState(() {
              _isLoadingDetails = false;
            });
          });
        }
      },
    );
  }
}