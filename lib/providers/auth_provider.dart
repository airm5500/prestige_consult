import 'package:flutter/material.dart';
import 'package:prestigeconsult/core/api/api_service.dart';
import 'package:prestigeconsult/models/user.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Clés pour le stockage
  static const String _userKey = 'authUser';
  static const String _rememberMeKey = 'rememberMe';
  static const String _loginKey = 'savedLogin';
  static const String _passwordKey = 'savedPassword';

  User? _user; // L'utilisateur actuellement connecté
  bool _isAuthenticated = false; // Flag pour savoir si l'utilisateur est authentifié
  bool _rememberMe = false; // Pour la case "Rester connecté"

  String _savedLogin = '';
  String _savedPassword = '';

  // Getters publics
  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get rememberMe => _rememberMe;
  String get savedLogin => _savedLogin;
  String get savedPassword => _savedPassword;

  AuthProvider() {
    _loadRememberMe(); // Charge les identifiants sauvegardés au démarrage
  }

  // Tente de connecter l'utilisateur
  Future<bool> login(String login, String password, AppConfigProvider config) async {
    try {
      final response = await _apiService.post(
        '/user/auth',
        config,
        body: {'login': login, 'password': password},
      );

      if (response['success'] == true) {
        _user = User.fromJson(response);
        _isAuthenticated = true;

        // Gère la sauvegarde des identifiants si "Rester connecté" est coché
        if (_rememberMe) {
          _saveCredentials(login, password);
        } else {
          _clearCredentials();
        }

        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Les erreurs (réseau, session) sont propagées par l'ApiService
      rethrow;
    }
  }

  // Déconnecte l'utilisateur
  Future<void> logout(AppConfigProvider config) async {
    try {
      // Informe le serveur de la déconnexion, même si on ignore la réponse.
      await _apiService.post('/user/logout', config);
    } catch (e) {
      // On ignore les erreurs ici, la déconnexion doit fonctionner même sans réseau.
    } finally {
      _user = null;
      _isAuthenticated = false;
      _apiService.clearSession(); // Très important: efface le cookie de session
      notifyListeners();
    }
  }

  // Gère l'état de la case "Rester connecté"
  void setRememberMe(bool value) {
    _rememberMe = value;
    final prefs = SharedPreferences.getInstance();
    prefs.then((p) => p.setBool(_rememberMeKey, value));
    if (!value) {
      _clearCredentials(); // Si on décoche, on efface les identifiants
    }
    notifyListeners();
  }

  // Charge les préférences "Rester connecté" et les identifiants
  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    if (_rememberMe) {
      _savedLogin = prefs.getString(_loginKey) ?? '';
      _savedPassword = prefs.getString(_passwordKey) ?? '';
    }
    notifyListeners();
  }

  // Sauvegarde les identifiants
  Future<void> _saveCredentials(String login, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginKey, login);
    await prefs.setString(_passwordKey, password);
    _savedLogin = login;
    _savedPassword = password;
  }

  // Efface les identifiants sauvegardés
  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginKey);
    await prefs.remove(_passwordKey);
    _savedLogin = '';
    _savedPassword = '';
  }
}