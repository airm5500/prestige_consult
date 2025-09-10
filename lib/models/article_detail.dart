import 'package:intl/intl.dart';

class ArticleDetail {
  final String codeCip;
  final String libelle;
  final double prixVente;
  final String emplacement;
  final double moyenne;
  final double prixAchat;
  final String grossiste;
  final String produitId;
  final String quantiteMoisRaw; // Garde la donnée brute "1:2,1:6..."
  final int quantiteVendue;

  ArticleDetail({
    required this.codeCip,
    required this.libelle,
    required this.prixVente,
    required this.emplacement,
    required this.moyenne,
    required this.prixAchat,
    required this.grossiste,
    required this.produitId,
    required this.quantiteMoisRaw,
    required this.quantiteVendue,
  });

  factory ArticleDetail.fromJson(Map<String, dynamic> json) {
    // Utilise tryParse pour éviter les erreurs si les nombres sont mal formatés
    return ArticleDetail(
      codeCip: json['codeCip'] ?? '',
      libelle: json['libelle'] ?? 'N/A',
      prixVente: double.tryParse(json['prixVente']?.toString() ?? '0.0') ?? 0.0,
      emplacement: json['emplacement'] ?? 'N/A',
      moyenne: double.tryParse(json['moyenne']?.toString() ?? '0.0') ?? 0.0,
      prixAchat: double.tryParse(json['prixAchat']?.toString() ?? '0.0') ?? 0.0,
      grossiste: json['grossiste'] ?? 'N/A',
      produitId: json['produitId'] ?? '',
      quantiteMoisRaw: json['quantiteMois'] ?? '',
      quantiteVendue: json['quantiteVendue'] ?? 0,
    );
  }

  // Méthode helper pour convertir la chaîne "quantiteMois" en une Map lisible
  // Exemple: "1:2,5:3" devient {2: 1, 3: 5} -> {Février: 1, Mars: 5}
  Map<int, int> get salesByMonth {
    final map = <int, int>{};
    if (quantiteMoisRaw.isEmpty) return map;

    final parts = quantiteMoisRaw.split(',');
    for (var part in parts) {
      final subParts = part.split(':');
      if (subParts.length == 2) {
        final quantite = int.tryParse(subParts[0]);
        final mois = int.tryParse(subParts[1]);
        if (quantite != null && mois != null) {
          map[mois] = (map[mois] ?? 0) + quantite;
        }
      }
    }
    return map;
  }

  // Méthode pour formater les ventes mensuelles pour l'affichage
  List<String> get formattedMonthlySales {
    final List<String> result = [];
    final sales = salesByMonth;

    // S'assure que les mois sont triés
    final sortedMonths = sales.keys.toList()..sort();

    for (var month in sortedMonths) {
      // Utilise DateFormat pour obtenir le nom du mois en français
      final monthName = DateFormat.MMMM('fr_FR').format(DateTime(DateTime.now().year, month));
      result.add('${monthName[0].toUpperCase()}${monthName.substring(1)}: ${sales[month]}');
    }
    return result;
  }
}