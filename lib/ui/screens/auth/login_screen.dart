import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:prestigeconsult/core/config/app_config.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';
import 'package:prestigeconsult/providers/auth_provider.dart';
import 'package:prestigeconsult/ui/widgets/custom_button.dart';
import 'package:prestigeconsult/ui/widgets/custom_text_field.dart';
import 'package:prestigeconsult/utils/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplir les champs si "Rester connecté" était activé
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _loginController.text = authProvider.savedLogin;
    _passwordController.text = authProvider.savedPassword;
  }

  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final configProvider = Provider.of<AppConfigProvider>(context, listen: false);

    try {
      final success = await authProvider.login(
        _loginController.text,
        _passwordController.text,
        configProvider,
      );

      if (success) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      } else {
        Fluttertoast.showToast(msg: "Login ou mot de passe incorrect.");
      }
    } catch (e) {
      // Affiche l'erreur venant de l'ApiService (ex: réseau, session expirée)
      Fluttertoast.showToast(msg: e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Consumer permet de reconstruire UNIQUEMENT les widgets qui dépendent des providers
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.business_center, size: 80, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text(
                  'PrestigeConsult',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 40),

                // Champ Login
                CustomTextField(
                  controller: _loginController,
                  labelText: 'Login',
                  icon: Icons.person,
                ),
                const SizedBox(height: 20),

                // Champ Mot de passe
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Mot de passe',
                  icon: Icons.lock,
                  isPassword: true,
                ),
                const SizedBox(height: 20),

                // Switch Local/Distant et Checkbox "Rester connecté"
                _buildConnectionAndRememberMe(),

                const SizedBox(height: 30),

                // Bouton de connexion
                CustomButton(
                  text: 'Se connecter',
                  onPressed: _performLogin,
                  isLoading: _isLoading,
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                  child: const Text('Modifier la configuration'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionAndRememberMe() {
    return Consumer2<AppConfigProvider, AuthProvider>(
      builder: (context, config, auth, child) {
        return Column(
          children: [
            SwitchListTile(
              title: const Text('Connexion Distante'),
              subtitle: Text(config.connectionMode == ConnectionMode.local ? 'Mode: Local' : 'Mode: Distant'),
              value: config.connectionMode == ConnectionMode.distant,
              onChanged: (value) {
                config.setConnectionMode(value ? ConnectionMode.distant : ConnectionMode.local);
              },
              activeThumbColor: AppColors.primary,
            ),
            CheckboxListTile(
              title: const Text('Rester connecté'),
              value: auth.rememberMe,
              onChanged: (value) {
                if (value != null) {
                  auth.setRememberMe(value);
                }
              },
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
            ),
          ],
        );
      },
    );
  }
}