import 'package:prestigeconsult/models/nested_product.dart';

// Représente un article dans la liste "bonLivraisonDetails"
class DeliverySlipItem {
  final String id;
  final NestedProduct produit;
  final int qteRecue;
  final int stockInitial;
  int quantiteComptee; // Champ pour la saisie utilisateur

  DeliverySlipItem({
    required this.id,
    required this.produit,
    required this.qteRecue,
    required this.stockInitial,
    this.quantiteComptee = 0, // Initialisé à 0
  });

  // Calcule le stock théorique pour le rapport final
  int get stockTheorique => stockInitial + qteRecue;

  factory DeliverySlipItem.fromJson(Map<String, dynamic> json) {
    return DeliverySlipItem(
      id: json['lgBONLIVRAISONDETAIL'] ?? '',
      produit: NestedProduct.fromJson(json['produit'] ?? {}),
      qteRecue: json['intQTERECUE'] ?? 0,
      stockInitial: json['intINITSTOCK'] ?? 0,
    );
  }
}