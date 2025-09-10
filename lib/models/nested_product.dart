// Représente l'objet "produit" à l'intérieur d'un article de bon de livraison
class NestedProduct {
  final String cip;
  final String name;

  NestedProduct({required this.cip, required this.name});

  factory NestedProduct.fromJson(Map<String, dynamic> json) {
    return NestedProduct(
      cip: json['intCIP'] ?? 'N/A',
      name: json['strNAME'] ?? 'Produit Inconnu',
    );
  }
}