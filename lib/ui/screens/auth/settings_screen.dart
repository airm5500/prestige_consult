import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:prestigeconsult/core/api/api_service.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';
import 'package:prestigeconsult/ui/widgets/custom_button.dart';
import 'package:prestigeconsult/utils/app_routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Contrôleurs pour les champs de texte
  final _localIpController = TextEditingController();
  final _distantIpController = TextEditingController();
  final _portController = TextEditingController();
  final _appNameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  bool _isSaving = false;
  String _localPingResult = '';
  String _distantPingResult = '';
  bool _isPingingLocal = false;
  bool _isPingingDistant = false;

  @override
  void initState() {
    super.initState();
    // Initialise les champs avec les valeurs existantes du provider
    final configProvider = Provider.of<AppConfigProvider>(context, listen: false);
    _localIpController.text = configProvider.localApiAddress;
    _distantIpController.text = configProvider.distantApiAddress;
    _portController.text = configProvider.apiPort;
    _appNameController.text = configProvider.appName;
  }

  // Fonction pour tester la connexion à une IP
  Future<void> _pingServer(bool isLocal) async {
    setState(() {
      if (isLocal) {
        _isPingingLocal = true;
        _localPingResult = 'Test en cours...';
      } else {
        _isPingingDistant = true;
        _distantPingResult = 'Test en cours...';
      }
    });

    final ip = isLocal ? _localIpController.text : _distantIpController.text;
    final port = _portController.text;
    final appName = _appNameController.text;

    if (ip.isEmpty) {
      setState(() {
        if (isLocal) {
          _isPingingLocal = false;
          _localPingResult = 'L\'adresse IP est vide.';
        } else {
          _isPingingDistant = false;
          _distantPingResult = 'L\'adresse IP est vide.';
        }
      });
      return;
    }

    // Construit une URL simple juste pour le ping
    final url = "http://$ip:$port/$appName";
    final success = await _apiService.ping(url);

    setState(() {
      if (isLocal) {
        _isPingingLocal = false;
        _localPingResult = success ? '✅ Succès' : '❌ Échec';
      } else {
        _isPingingDistant = false;
        _distantPingResult = success ? '✅ Succès' : '❌ Échec';
      }
    });
  }

  // Fonction pour sauvegarder la configuration
  Future<void> _saveConfiguration() async {
    // Valide le formulaire
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    // Un ping de l'IP locale est obligatoire avant de sauvegarder
    final localUrl = "http://${_localIpController.text}:${_portController.text}/${_appNameController.text}";
    final success = await _apiService.ping(localUrl);

    if (!success) {
      Fluttertoast.showToast(msg: "Le ping de l'adresse locale a échoué. Veuillez vérifier.");
      setState(() => _isSaving = false);
      return;
    }

    final configProvider = Provider.of<AppConfigProvider>(context, listen: false);
    await configProvider.saveConfig(
      localIp: _localIpController.text,
      distantIp: _distantIpController.text,
      port: _portController.text,
      appName: _appNameController.text,
    );

    setState(() => _isSaving = false);

    Fluttertoast.showToast(msg: "Configuration enregistrée avec succès !");

    // Redirige vers l'écran de connexion en remplaçant l'écran actuel
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _localIpController.dispose();
    _distantIpController.dispose();
    _portController.dispose();
    _appNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration du Serveur'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Veuillez configurer les informations de connexion à votre serveur.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),

              // Champ IP Locale
              TextFormField(
                controller: _localIpController,
                decoration: InputDecoration(
                  labelText: 'Adresse IP Locale *',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isPingingLocal
                      ? const Padding(padding: EdgeInsets.all(10.0), child: CircularProgressIndicator())
                      : IconButton(
                    icon: const Icon(Icons.network_check),
                    onPressed: () => _pingServer(true),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              Text(_localPingResult, style: TextStyle(color: _localPingResult.contains('Succès') ? Colors.green : Colors.red)),
              const SizedBox(height: 16),

              // Champ IP Distante
              TextFormField(
                controller: _distantIpController,
                decoration: InputDecoration(
                  labelText: 'Adresse IP Distante',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isPingingDistant
                      ? const Padding(padding: EdgeInsets.all(10.0), child: CircularProgressIndicator())
                      : IconButton(
                    icon: const Icon(Icons.network_check),
                    onPressed: () => _pingServer(false),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              Text(_distantPingResult, style: TextStyle(color: _distantPingResult.contains('Succès') ? Colors.green : Colors.red)),
              const SizedBox(height: 16),

              // Champ Port
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(labelText: 'Port *', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),

              // Champ Nom de l'application
              TextFormField(
                controller: _appNameController,
                decoration: const InputDecoration(labelText: 'Nom Application Serveur *', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 32),

              // Bouton Enregistrer
              CustomButton(
                text: 'Enregistrer',
                onPressed: _saveConfiguration,
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}