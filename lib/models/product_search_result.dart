class ProductState {
  final int enCommande;
  final int entree;
  final int enSuggestion;

  ProductState({
    required this.enCommande,
    required this.entree,
    required this.enSuggestion,
  });

  factory ProductState.fromJson(Map<String, dynamic> json) {
    return ProductState(
      enCommande: json['enCommande'] ?? 0,
      entree: json['entree'] ?? 0,
      enSuggestion: json['enSuggestion'] ?? 0,
    );
  }
}

class ProductSearchResult {
  final String id; // lg_FAMILLE_ID
  final String cip;
  final String name;
  final int price;
  final int paf;
  final String ean13;
  final String emplacement;
  final int stock;
  final String dateCreation;
  final String dateDernierInventaire;
  final String dateDerniereLivraison;
  final String dateDerniereEntree;
  final String dateDerniereVente;
  final int quantiteDansBoite;
  final String datePeremption;
  final ProductState produitState;

  ProductSearchResult({
    required this.id,
    required this.cip,
    required this.name,
    required this.price,
    required this.paf,
    required this.ean13,
    required this.emplacement,
    required this.stock,
    required this.dateCreation,
    required this.dateDernierInventaire,
    required this.dateDerniereLivraison,
    required this.dateDerniereEntree,
    required this.dateDerniereVente,
    required this.quantiteDansBoite,
    required this.datePeremption,
    required this.produitState,
  });

  factory ProductSearchResult.fromJson(Map<String, dynamic> json) {
    return ProductSearchResult(
      id: json['lg_FAMILLE_ID'] ?? '',
      cip: json['int_CIP']?.toString() ?? 'N/A',
      name: json['str_NAME'] ?? 'N/A',
      price: json['int_PRICE'] ?? 0,
      paf: json['int_PAF'] ?? 0,
      ean13: json['int_EAN13']?.toString() ?? 'N/A',
      emplacement: json['lg_ZONE_GEO_ID'] ?? 'N/A',
      stock: json['int_NUMBER'] ?? 0,
      dateCreation: json['dt_CREATED'] ?? 'N/A',
      dateDernierInventaire: json['dt_LAST_INVENTAIRE'] ?? 'N/A',
      dateDerniereLivraison: json['dt_DATE_LIVRAISON'] ?? 'N/A',
      dateDerniereEntree: json['dt_LAST_ENTREE'] ?? 'N/A',
      dateDerniereVente: json['dt_LAST_VENTE'] ?? 'N/A',
      quantiteDansBoite: json['int_NUMBERDETAIL'] ?? 0,
      datePeremption: json['dtPEREMPTION'] ?? 'N/A',
      produitState: ProductState.fromJson(json['produitState'] ?? {}),
    );
  }
}