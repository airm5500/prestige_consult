import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prestigeconsult/core/api/api_service.dart';
import 'package:prestigeconsult/core/logic/base_screen_logic.dart';
import 'package:prestigeconsult/models/product_search_result.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';
import 'package:prestigeconsult/ui/screens/features/update_peremption/update_date_dialog.dart';

class UpdatePeremptionScreen extends StatefulWidget {
  const UpdatePeremptionScreen({super.key});

  @override
  State<UpdatePeremptionScreen> createState() => _UpdatePeremptionScreenState();
}

class _UpdatePeremptionScreenState extends State<UpdatePeremptionScreen> with BaseScreenLogic {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _apiService = ApiService();
  Timer? _debounce;

  List<ProductSearchResult> _searchResults = [];
  bool _showResultsList = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _performSearch);
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showResultsList = false;
      });
      return;
    }

    final endpoint = '/produit-search/fiche?search_value=$query&limit=10';
    final response = await runApiCall(
          () => _apiService.get(endpoint, Provider.of<AppConfigProvider>(context, listen: false)),
      showToastOnError: false,
    );

    if (mounted && response != null && response['results'] is List) {
      final results = response['results'].map<ProductSearchResult>((json) => ProductSearchResult.fromJson(json)).toList();
      setState(() {
        _searchResults = results;
        _showResultsList = true;
      });

      // OPTIMISATION SCAN: Si un seul résultat, on le sélectionne automatiquement
      if (_searchResults.length == 1) {
        _onProductSelected(_searchResults.first);
      }
    }
  }

  Future<void> _onProductSelected(ProductSearchResult product) async {
    setState(() {
      _showResultsList = false; // Cache la liste des résultats
    });

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // L'utilisateur doit choisir "Annuler" ou "Valider"
      builder: (_) => UpdateDateDialog(product: product),
    );

    // Si la mise à jour a réussi (dialogue a retourné true), on réinitialise l'écran
    if (success == true) {
      _resetScreen();
    }
  }

  void _resetScreen() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _showResultsList = false;
    });
    // Remet le focus sur la barre de recherche pour le prochain scan/recherche
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mise à Jour Péremption')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Barre de recherche ---
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Scanner ou rechercher un produit...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: _resetScreen)
                      : null,
                ),
              ),

              // --- Zone d'affichage des résultats ---
              Expanded(
                child: Stack(
                  children: [
                    // On peut mettre un fond informatif ici si on le souhaite
                    if (!_showResultsList)
                      const Center(child: Text('En attente de recherche...')),

                    // --- Liste de résultats (superposée) ---
                    if (_showResultsList)
                      Card(
                        margin: const EdgeInsets.only(top: 8.0),
                        elevation: 4,
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final product = _searchResults[index];
                            return ListTile(
                              title: Text(product.name),
                              subtitle: Text('CIP: ${product.cip} | Stock: ${product.stock}'),
                              onTap: () => _onProductSelected(product),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}