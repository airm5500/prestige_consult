import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:prestigeconsult/core/api/api_service.dart';
import 'package:prestigeconsult/core/logic/base_screen_logic.dart';
import 'package:prestigeconsult/models/delivery_slip.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';
import 'package:prestigeconsult/ui/screens/features/stock_entry/stock_count_screen.dart';
// Importer l'écran de comptage que nous créerons après
// import 'package:prestigeconsult/ui/screens/features/stock_entry/stock_count_screen.dart';


class DeliverySlipListScreen extends StatefulWidget {
  const DeliverySlipListScreen({super.key});

  @override
  State<DeliverySlipListScreen> createState() => _DeliverySlipListScreenState();
}

class _DeliverySlipListScreenState extends State<DeliverySlipListScreen> with BaseScreenLogic {
  List<DeliverySlip> _deliverySlips = [];
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSlips());
  }

  Future<void> _loadSlips() async {
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
      _loadSlips();
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
              onRefresh: _loadSlips,
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

  Widget _buildDateButton(bool isStartDate) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.calendar_today),
      label: Text(isStartDate
          ? 'Du: ${DateFormat('dd/MM/yy').format(_startDate)}'
          : 'Au: ${DateFormat('dd/MM/yy').format(_endDate)}'),
      onPressed: () => _selectDate(context, isStartDate),
    );
  }

  Widget _buildSlipList() {
    return ListView.builder(
      itemCount: _deliverySlips.length,
      itemBuilder: (context, index) {
        final slip = _deliverySlips[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(slip.fournisseur.libelle, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Réf: ${slip.referenceLivraison}\nDate: ${slip.dateLivraison}'),
            trailing: Chip(label: Text('${slip.items.length} produits')),
            onTap: () {
              // TODO: Naviguer vers l'écran de comptage
              Navigator.push(context, MaterialPageRoute(builder: (_) => StockCountScreen(deliverySlip: slip)));
            },
          ),
        );
      },
    );
  }
}