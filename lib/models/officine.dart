class Officine {
  final String id;
  final String nomComplet;
  final String fullNameDr; // Le champ "fullName" de l'API

  Officine({
    required this.id,
    required this.nomComplet,
    required this.fullNameDr,
  });

  factory Officine.fromJson(Map<String, dynamic> json) {
    return Officine(
      id: json['id'] ?? '',
      nomComplet: json['nomComplet'] ?? 'Nom de la pharmacie non disponible',
      fullNameDr: json['fullName'] ?? 'Dr. Anonyme',
    );
  }
}