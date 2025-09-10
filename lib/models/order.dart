class Order {
  final String id;
  final String reference;
  final String grossisteName;
  final String dateCreation;
  final int productCount;
  final double totalAchat;
  final double totalVente;

  Order({
    required this.id,
    required this.reference,
    required this.grossisteName,
    required this.dateCreation,
    required this.productCount,
    required this.totalAchat,
    required this.totalVente,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['lg_ORDER_ID'] ?? '',
      reference: json['str_REF_ORDER'] ?? 'N/A',
      grossisteName: json['str_GROSSISTE_LIBELLE'] ?? 'N/A',
      dateCreation: json['dt_CREATED'] ?? 'N/A',
      productCount: json['int_NBRE_PRODUIT'] ?? 0,
      totalAchat: (json['PRIX_ACHAT_TOTAL'] ?? 0).toDouble(),
      totalVente: (json['PRIX_VENTE_TOTAL'] ?? 0).toDouble(),
    );
  }
}