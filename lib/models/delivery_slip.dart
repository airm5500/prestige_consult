// ... importations
import 'package:prestigeconsult/models/nested_fournisseur.dart';
import 'package:prestigeconsult/models/delivery_slip_item.dart';

class DeliverySlip {
  final String id;
  final String referenceLivraison;
  final String dateLivraison;
  final NestedFournisseur fournisseur;
  final List<DeliverySlipItem> items;
  final double totalHT; // <-- NOUVEAU CHAMP
  final String userName;  // <-- NOUVEAU CHAMP

  DeliverySlip({
    required this.id,
    required this.referenceLivraison,
    required this.dateLivraison,
    required this.fournisseur,
    required this.items,
    required this.totalHT,   // <-- NOUVEAU CHAMP
    required this.userName,  // <-- NOUVEAU CHAMP
  });

  factory DeliverySlip.fromJson(Map<String, dynamic> json) {
    var itemsList = <DeliverySlipItem>[];
    if (json['bonLivraisonDetails'] is List) {
      itemsList = (json['bonLivraisonDetails'] as List)
          .map((itemJson) => DeliverySlipItem.fromJson(itemJson))
          .toList();
    }

    return DeliverySlip(
      id: json['lgBONLIVRAISONID'] ?? '',
      referenceLivraison: json['strREFLIVRAISON'] ?? 'N/A',
      dateLivraison: json['dtDATELIVRAISON'] ?? 'N/A',
      fournisseur: NestedFournisseur.fromJson(json['fournisseur'] ?? {}),
      items: itemsList,
      totalHT: (json['intHTTC'] ?? 0).toDouble(), // <-- NOUVEAU CHAMP
      userName: json['userName'] ?? 'N/A',      // <-- NOUVEAU CHAMP
    );
  }
}