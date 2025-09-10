import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:prestigeconsult/core/api/api_service.dart';
import 'package:prestigeconsult/core/logic/base_screen_logic.dart';
import 'package:prestigeconsult/models/product_search_result.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';

class UpdatePeremptionScreen extends StatefulWidget {
  const UpdatePeremptionScreen({super.key});

  @override
  State<UpdatePeremptionScreen> createState() => _UpdatePeremptionScreenState();
}

class _UpdatePeremptionScreenState extends State<UpdatePeremptionScreen> with BaseScreenLogic {
  final _searchController = TextEditingController();
  final _apiService = ApiService();
  Timer? _debounce;

  // --- State Variables ---
  List<ProductSearchResult> _searchResults = [];
  bool _showResultsList = false;
  ProductSearchResult? _selectedProduct;
  DateTime? _newExpirationDate;

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
      showToastOnError: false, // On gère l'erreur silencieusement
    );

    if (response != null && response['results'] is List) {
      setState(() {
        _searchResults = response['results'].map<ProductSearchResult>((json) => ProductSearchResult.fromJson(json)).toList();
        _showResultsList = true;
      });
    }
  }

  void _onProductSelected(ProductSearchResult product) {
    setState(() {
      _selectedProduct = product;
      _searchController.text = product.name; // Affiche le nom dans la barre de recherche
      _searchResults = [];
      _showResultsList = false;
    });
    // Ferme le clavier
    FocusScope.of(context).unfocus();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _newExpirationDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
      locale: const Locale('fr', 'FR'), // Assure que le calendrier est en français
    );
    if (picked != null && picked != _newExpirationDate) {
      setState(() {
        _newExpirationDate = picked;
      });
    }
  }

  Future<void> _performUpdate() async {
    if (_selectedProduct == null || _newExpirationDate == null) {
      Fluttertoast.showToast(msg: "Veuillez sélectionner un produit et une date.");
      return;
    }

    final dateFormatted = DateFormat('yyyy-MM-dd').format(_newExpirationDate!);
    final endpoint = '/fichearticle/dateperemption/${_selectedProduct!.id}/$dateFormatted';

    // Pour une requête PUT sans corps, on passe un body vide.
    final response = await runApiCall(() => _apiService.put(endpoint, Provider.of<AppConfigProvider>(context, listen: false), body: {}));

    if (response != null && response['success'] == true) {
      Fluttertoast.showToast(
        msg: "Date mise à jour avec succès !",
        backgroundColor: Colors.green,
      );
      // Réinitialise l'écran pour la prochaine recherche
      _resetScreen();
    } else {
      Fluttertoast.showToast(
        msg: "Échec de la mise à jour.",
        backgroundColor: Colors.red,
      );
    }
  }

  void _resetScreen() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _showResultsList = false;
      _selectedProduct = null;
      _newExpirationDate = null;
    });
    // Remet le focus sur la barre de recherche pour un enchaînement rapide
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mise à Jour Péremption')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Permet de fermer le clavier en touchant l'écran
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Barre de recherche ---
              _buildSearchBar(),

              // --- Liste de résultats (superposée) ---
              if (_showResultsList) _buildResultsOverlay(),

              const SizedBox(height: 24),

              // --- Zone de sélection ---
              _buildSelectionArea(),

              const Spacer(), // Pousse le bouton vers le bas

              // --- Bouton de validation ---
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Mettre à jour'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: (_selectedProduct != null && _newExpirationDate != null && !isLoading)
                    ? _performUpdate
                    : null, // Le bouton est désactivé si rien n'est sélectionné ou en cours de chargement
              ),
              if(isLoading) const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        labelText: 'Scanner ou rechercher un produit...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear), onPressed: _resetScreen)
            : null,
      ),
    );
  }

  Widget _buildResultsOverlay() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: Card(
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
    );
  }

  Widget _buildSelectionArea() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Produit Sélectionné', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            _selectedProduct == null
                ? const Text('En attente de sélection...')
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedProduct!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Péremption actuelle: ${_selectedProduct!.datePeremption}'),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _newExpirationDate == null
                      ? 'Choisir une nouvelle date'
                      : 'Nouvelle date: ${DateFormat('dd/MM/yyyy').format(_newExpirationDate!)}',
                  style: const TextStyle(fontSize: 16),
                ),
                onPressed: _selectedProduct != null ? _selectDate : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}