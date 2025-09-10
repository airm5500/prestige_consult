import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prestigeconsult/core/api/api_service.dart';
import 'package:prestigeconsult/core/logic/base_screen_logic.dart';
import 'package:prestigeconsult/models/delivery_slip.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';
import 'package:prestigeconsult/ui/screens/features/stock_entry/stock_count_screen.dart';

class DeliverySlipListScreen extends StatefulWidget {
  const DeliverySlipListScreen({super.key});

  @override
  State<DeliverySlipListScreen> createState() => _DeliverySlipListScreenState();
}

class _DeliverySlipListScreenState extends State<DeliverySlipListScreen> with BaseScreenLogic {
  List<DeliverySlip> _deliverySlips = [];
  List<String> _controlledSlipIds = []; // Liste des IDs des BLs contrôlés localement
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  // Charge à la fois les BLs de l'API et les statuts de contrôle locaux
  Future<void> _loadData() async {
    await _loadControlledSlipsFromLocal();
    await _loadSlipsFromApi();
  }

  // Lit la liste des IDs sauvegardés sur le téléphone
  Future<void> _loadControlledSlipsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _controlledSlipIds = prefs.getStringList('controlled_slip_ids') ?? [];
      });
    }
  }

  // Récupère la liste des BLs depuis le serveur
  Future<void> _loadSlipsFromApi() async {
    final dtStart = DateFormat('yyyy-MM-dd').format(_startDate);
    final dtEnd = DateFormat('yyyy-MM-dd').format(_endDate);
    final endpoint = '/etat-control-bon/list?search=&grossisteId=&dtStart=$dtStart&dtEnd=$dtEnd&limit=100';

    final response = await runApiCall(() =>
        ApiService().get(endpoint, Provider.of<AppConfigProvider>(context, listen: false))
    );

    if (mounted && response != null && response['data'] is List) {
      final slipsData = response['data'] as List;
      setState(() {
        _deliverySlips = slipsData.map((json) => DeliverySlip.fromJson(json)).toList();
      });
    }
  }

  // Affiche le sélecteur de date
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      // Recharge les données avec la nouvelle période
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bons de Livraison')),
      body: Column(
        children: [
          _buildDateFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _deliverySlips.isEmpty
                  ? const Center(child: Text('Aucun bon de livraison pour cette période.'))
                  : _buildSlipList(),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour les filtres de date
  Widget _buildDateFilters() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildDateButton(true)),
          const SizedBox(width: 10),
          Expanded(child: _buildDateButton(false)),
        ],
      ),
    );
  }

  // Widget pour un bouton de date
  Widget _buildDateButton(bool isStartDate) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(isStartDate
          ? 'Du: ${DateFormat('dd/MM/yy').format(_startDate)}'
          : 'Au: ${DateFormat('dd/MM/yy').format(_endDate)}'),
      onPressed: () => _selectDate(context, isStartDate),
    );
  }

  // Widget pour la liste des BLs
  Widget _buildSlipList() {
    return ListView.builder(
      itemCount: _deliverySlips.length,
      itemBuilder: (context, index) {
        final slip = _deliverySlips[index];
        final isControlled = _controlledSlipIds.contains(slip.id);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: isControlled
                ? const Icon(Icons.check_circle, color: Colors.green, size: 30)
                : const Icon(Icons.receipt_long_outlined, size: 30),
            title: Text(slip.fournisseur.libelle, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                'Réf: ${slip.referenceLivraison} | ${slip.dateLivraison}\n'
                    'Montant: ${slip.totalHT} FCFA | ${slip.items.length} produits | Par: ${slip.userName}'
            ),
            isThreeLine: true,
            onTap: () async {
              // Navigue vers l'écran de comptage
              await Navigator.push(context, MaterialPageRoute(builder: (_) =>
                  StockCountScreen(deliverySlip: slip, isAlreadyControlled: isControlled)
              ));
              // Au retour, on recharge les données pour mettre à jour l'icône ✔️
              _loadData();
            },
          ),
        );
      },
    );
  }
}