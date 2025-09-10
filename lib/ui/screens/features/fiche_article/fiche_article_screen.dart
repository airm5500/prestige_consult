import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prestigeconsult/core/api/api_service.dart';
import 'package:prestigeconsult/core/logic/base_screen_logic.dart';
import 'package:prestigeconsult/models/article_detail.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';
import 'package:prestigeconsult/ui/screens/features/fiche_article/fiche_article_detail_screen.dart';
import 'package:shimmer/shimmer.dart';

class FicheArticleScreen extends StatefulWidget {
  const FicheArticleScreen({super.key});

  @override
  State<FicheArticleScreen> createState() => _FicheArticleScreenState();
}

class _FicheArticleScreenState extends State<FicheArticleScreen> with BaseScreenLogic {
  final _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<ArticleDetail> _searchResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Se déclenche à chaque modification du texte de recherche
  void _onSearchChanged() {
    // Annule le timer précédent s'il existe
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    // Crée un nouveau timer de 500ms
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    // Applique les règles de recherche
    final isNumeric = int.tryParse(query) != null;
    if (query.isEmpty || (isNumeric && query.length < 3) || (!isNumeric && query.length < 2)) {
      setState(() => _searchResults = []);
      return;
    }

    final configProvider = Provider.of<AppConfigProvider>(context, listen: false);
    final response = await runApiCall(() => _apiService.get('/info?search=$query', configProvider));

    if (response != null && response is List) {
      setState(() {
        _searchResults = response.map((json) => ArticleDetail.fromJson(json)).toList();
      });
    } else {
      setState(() => _searchResults = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiche Article'),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Rechercher par CIP ou libellé...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchResults = []);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (isLoading) {
      return _buildLoadingShimmer();
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(child: Text('Aucun résultat trouvé.'));
    }

    if (_searchResults.isEmpty) {
      return const Center(child: Text('Commencez votre recherche.'));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final article = _searchResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Nom: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: article.libelle),
                ],
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'CIP: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: article.codeCip),
                    ],
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Prix: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '${article.prixVente.toStringAsFixed(0)} FCFA'),
                    ],
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Moy: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: article.moyenne.toStringAsFixed(2)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              // Navigation vers l'écran de détail
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FicheArticleDetailScreen(article: article),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Container(height: 16, width: 200, color: Colors.white),
            subtitle: Container(height: 12, width: 150, color: Colors.white, margin: const EdgeInsets.only(top: 8)),
          ),
        ),
      ),
    );
  }
}