import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';
import 'package:prestigeconsult/providers/auth_provider.dart';
import 'package:prestigeconsult/ui/screens/auth/login_screen.dart';
import 'package:prestigeconsult/ui/screens/auth/settings_screen.dart';
import 'package:prestigeconsult/utils/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  // Assure que les bindings Flutter sont initialisés avant toute autre chose.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise les données de localisation pour le français.
  // Cela est crucial pour que les dates s'affichent correctement (ex: "Lundi", "Janvier").
  await initializeDateFormatting('fr_FR', null);

  // Crée les instances des providers.
  final appConfigProvider = AppConfigProvider();
  await appConfigProvider.loadConfig(); // Charge la configuration au démarrage.

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => appConfigProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Ajoutez d'autres providers ici si nécessaire.
      ],
      child: MyApp(appConfigProvider: appConfigProvider),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppConfigProvider appConfigProvider;

  const MyApp({super.key, required this.appConfigProvider});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrestigeConsult',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Utilise Google Fonts pour une typographie élégante.
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      // Configure la localisation pour le français.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      // Détermine la page d'accueil en fonction de la configuration.
      home: _getInitialScreen(),
      // Définit les routes pour la navigation entre les écrans.
      routes: AppRoutes.routes,
    );
  }

  // Cette méthode détermine l'écran à afficher au lancement.
  Widget _getInitialScreen() {
    // Si l'adresse IP locale n'est pas configurée, on force l'utilisateur
    // à aller sur l'écran de configuration. C'est une sécurité.
    if (!appConfigProvider.isConfigured()) {
      return const SettingsScreen();
    }

    // Si l'utilisateur est déjà authentifié (via "Rester connecté"),
    // on peut l'envoyer directement à l'accueil.
    // Note : La logique d'authentification persistante sera dans AuthProvider.
    // Pour l'instant, on redirige vers LoginScreen par défaut.
    return const LoginScreen();
  }
}