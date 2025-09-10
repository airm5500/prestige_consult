import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:prestigeconsult/providers/app_config_provider.dart';

// Classe ApiService implémentée en Singleton pour une instance unique.
class ApiService {
  // Instance privée et statique
  static final ApiService _instance = ApiService._internal();

  // Constructeur privé
  ApiService._internal();

  // Factory constructor pour retourner l'instance unique
  factory ApiService() {
    return _instance;
  }

  // Stocke le cookie de session (JSESSIONID)
  String? _sessionCookie;

  // Méthode pour construire l'URL de base à partir du provider de configuration.
  String _buildBaseUrl(AppConfigProvider config) {
    // Utilise la configuration actuelle (locale ou distante)
    return "${config.currentApiUrl}/api/v1";
  }

  // Méthode générique pour les requêtes GET
  Future<dynamic> get(String endpoint, AppConfigProvider config) async {
    final url = Uri.parse('${_buildBaseUrl(config)}$endpoint');
    try {
      final response = await http.get(url, headers: _getHeaders());
      return _processResponse(response);
    } on SocketException {
      // Gère les erreurs de réseau (pas d'internet, serveur injoignable)
      throw Exception('Erreur de connexion. Vérifiez votre réseau ou l\'adresse du serveur.');
    }
  }

  // Méthode générique pour les requêtes POST
  Future<dynamic> post(String endpoint, AppConfigProvider config, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('${_buildBaseUrl(config)}$endpoint');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: json.encode(body),
      );
      _updateCookie(response); // Met à jour le cookie après un appel (surtout pour le login)
      return _processResponse(response);
    } on SocketException {
      throw Exception('Erreur de connexion. Vérifiez votre réseau ou l\'adresse du serveur.');
    }
  }

  // Méthode générique pour les requêtes PUT
  Future<dynamic> put(String endpoint, AppConfigProvider config, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('${_buildBaseUrl(config)}$endpoint');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: json.encode(body),
      );
      return _processResponse(response);
    } on SocketException {
      throw Exception('Erreur de connexion. Vérifiez votre réseau ou l\'adresse du serveur.');
    }
  }


  // Construit les en-têtes pour chaque requête.
  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    // Ajoute le cookie de session s'il existe.
    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
    }
    return headers;
  }

  // Extrait et stocke le cookie de session à partir de la réponse du serveur.
  void _updateCookie(http.Response response) {
    final rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      // On ne garde que la partie JSESSIONID
      int index = rawCookie.indexOf(';');
      _sessionCookie = (index == -1) ? rawCookie : rawCookie.substring(0, index);
    }
  }

  // Efface le cookie de session lors de la déconnexion.
  void clearSession() {
    _sessionCookie = null;
  }

  // Traite la réponse HTTP.
  dynamic _processResponse(http.Response response) {
    // Décode le corps de la réponse qui est en JSON.
    final body = json.decode(utf8.decode(response.bodyBytes));

    switch (response.statusCode) {
      case 200: // OK
      case 201: // Created
        return body;
      case 401: // Unauthorized
      case 403: // Forbidden
      // Si la session a expiré, on efface le cookie et on lance une exception.
        clearSession();
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      default:
      // Gère les autres erreurs serveur.
        throw Exception('Erreur du serveur (code ${response.statusCode}).');
    }
  }

  // Méthode simple pour tester la connectivité (Ping)
  Future<bool> ping(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      // On considère un ping réussi si le serveur répond, peu importe le code status.
      return response.statusCode < 500; // Accepte tout sauf les erreurs serveur.
    } catch (e) {
      return false;
    }
  }
}