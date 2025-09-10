// Représente l'objet "fournisseur"
class NestedFournisseur {
  final String id;
  final String libelle;

  NestedFournisseur({required this.id, required this.libelle});

  factory NestedFournisseur.fromJson(Map<String, dynamic> json) {
    return NestedFournisseur(
      id: json['fournisseurId'] ?? '',
      libelle: json['fournisseurLibelle'] ?? 'N/A',
    );
  }
}