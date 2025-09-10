class ArticleEvaluation {
  final String id;
  final String codeCip;
  final String libelle;
  final Map<int, int> monthlySales; // Map<numéro du mois, quantité>

  ArticleEvaluation({
    required this.id,
    required this.codeCip,
    required this.libelle,
    required this.monthlySales,
  });

  factory ArticleEvaluation.fromJson(Map<String, dynamic> json) {
    const Map<String, int> monthMap = {
      'janvier': 1, 'fevrier': 2, 'mars': 3, 'avril': 4, 'mai': 5, 'juin': 6,
      'juillet': 7, 'aout': 8, 'septembre': 9, 'octobre': 10, 'novembre': 11, 'decembre': 12,
    };

    final sales = <int, int>{};
    monthMap.forEach((key, value) {
      if (json.containsKey(key)) {
        sales[value] = json[key] ?? 0;
      }
    });

    return ArticleEvaluation(
      id: json['id'] ?? '',
      codeCip: json['codeCip'] ?? '',
      libelle: json['libelle'] ?? 'N/A',
      monthlySales: sales,
    );
  }
}