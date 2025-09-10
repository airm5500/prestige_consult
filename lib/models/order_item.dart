class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String productCip;
  final int quantityOrdered; // La quantité en machine
  int quantityReceived; // La quantité saisie par l'utilisateur

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productCip,
    required this.quantityOrdered,
    this.quantityReceived = 0, // Par défaut à 0
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['lg_ORDERDETAIL_ID'] ?? '',
      productId: json['lg_FAMILLE_ID'] ?? '',
      productName: json['lg_FAMILLE_NAME'] ?? 'N/A',
      productCip: json['lg_FAMILLE_CIP']?.toString() ?? json['str_CODE_ARTICLE']?.toString() ?? '',
      quantityOrdered: json['int_NUMBER'] ?? 0,
    );
  }
}