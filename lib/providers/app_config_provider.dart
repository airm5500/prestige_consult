import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Énumération pour le mode de connexion
enum ConnectionMode { local, distant }

class AppConfigProvider with ChangeNotifier {
  // Clés pour le stockage dans SharedPreferences
  static const String _localIpKey = 'localApiAddress';
  static const String _distantIpKey = 'distantApiAddress';
  static const String _portKey = 'apiPort';
  static const String _appNameKey = 'appName';
  static const String _connectionModeKey = 'connectionMode';

  // Variables d'état privées
  String _localApiAddress = '';
  String _distantApiAddress = '';
  String _apiPort = '8080'; // Valeur par défaut
  String _appName = 'prestige'; // Valeur par défaut
  ConnectionMode _connectionMode = ConnectionMode.local;

  // Getters publics pour accéder aux valeurs en lecture seule
  String get localApiAddress => _localApiAddress;
  String get distantApiAddress => _distantApiAddress;
  String get apiPort => _apiPort;
  String get appName => _appName;
  ConnectionMode get connectionMode => _connectionMode;

  // Getter qui retourne l'URL de base actuelle en fonction du mode de connexion
  String get currentApiUrl {
    final address = _connectionMode == ConnectionMode.local ? _localApiAddress : _distantApiAddress;
    if (address.isEmpty) return '';
    return "http://$address:$_apiPort/$_appName";
  }

  // Vérifie si la configuration de base est faite
  bool isConfigured() {
    // La configuration est considérée comme valide si l'IP locale est renseignée
    return _localApiAddress.isNotEmpty;
  }

  // Charge la configuration depuis SharedPreferences au démarrage de l'app
  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _localApiAddress = prefs.getString(_localIpKey) ?? '';
    _distantApiAddress = prefs.getString(_distantIpKey) ?? '';
    _apiPort = prefs.getString(_portKey) ?? '8080';
    _appName = prefs.getString(_appNameKey) ?? 'prestige';
    _connectionMode = (prefs.getString(_connectionModeKey) ?? 'local') == 'local'
        ? ConnectionMode.local
        : ConnectionMode.distant;
    notifyListeners(); // Notifie les auditeurs d'un changement
  }

  // Sauvegarde la configuration dans SharedPreferences
  Future<void> saveConfig({
    required String localIp,
    required String distantIp,
    required String port,
    required String appName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localIpKey, localIp);
    await prefs.setString(_distantIpKey, distantIp);
    await prefs.setString(_portKey, port);
    await prefs.setString(_appNameKey, appName);

    // Met à jour les variables d'état locales
    _localApiAddress = localIp;
    _distantApiAddress = distantIp;
    _apiPort = port;
    _appName = appName;

    notifyListeners(); // Notifie que la configuration a changé
  }

  // Change le mode de connexion (Local/Distant)
  Future<void> setConnectionMode(ConnectionMode mode) async {
    if (_connectionMode != mode) {
      _connectionMode = mode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_connectionModeKey, mode == ConnectionMode.local ? 'local' : 'distant');
      notifyListeners();
    }
  }
}