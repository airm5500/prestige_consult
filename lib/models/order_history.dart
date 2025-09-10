class OrderHistory {
  final String grossiste;
  final String cip;
  final int quantite;
  final String dateEntree;
  final String datePeremption;

  OrderHistory({
    required this.grossiste,
    required this.cip,
    required this.quantite,
    required this.dateEntree,
    required this.datePeremption,
  });

  factory OrderHistory.fromJson(Map<String, dynamic> json) {
    return OrderHistory(
      grossiste: json['lg_GROSSISTE_ID'] ?? 'N/A',
      cip: json['int_CIP']?.toString() ?? 'N/A',
      quantite: json['int_NUMBER'] ?? 0,
      dateEntree: json['dt_ENTREE'] ?? 'N/A',
      datePeremption: json['dt_PEREMPTION'] ?? 'N/A',
    );
  }
}