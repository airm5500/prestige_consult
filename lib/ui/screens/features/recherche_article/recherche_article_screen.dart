import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prestigeconsult/core/api/api_service.dart';
import 'package:prestigeconsult/core/logic/base_screen_logic.dart';
import 'package:prestigeconsult/models/product_search_result.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';
import 'package:prestigeconsult/ui/screens/features/recherche_article/recherche_article_detail_screen.dart';

class RechercheArticleScreen extends StatefulWidget {
  const RechercheArticleScreen({super.key});

  @override
  State<RechercheArticleScreen> createState() => _RechercheArticleScreenState();
}

class _RechercheArticleScreenState extends State<RechercheArticleScreen> with BaseScreenLogic {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<ProductSearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _performSearch);
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final endpoint = '/produit-search/fiche?search_value=$query&str_TYPE_TRANSACTION=&lg_DCI_ID=&page=1&start=0&limit=20';
    final response = await runApiCall(() => ApiService().get(endpoint, Provider.of<AppConfigProvider>(context, listen: false)));

    if (response != null && response['results'] is List) {
      setState(() {
        _searchResults = response['results'].map<ProductSearchResult>((json) => ProductSearchResult.fromJson(json)).toList();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recherche Article')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher par CIP, nom ou scan...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final product = _searchResults[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text('CIP: ${product.cip} | Stock: ${product.stock} | Prix: ${product.price} FCFA'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => RechercheArticleDetailScreen(product: product),
                      ));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}