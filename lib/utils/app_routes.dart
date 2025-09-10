import 'package:flutter/material.dart';
import 'package:prestigeconsult/ui/screens/auth/login_screen.dart';
import 'package:prestigeconsult/ui/screens/auth/settings_screen.dart';
import 'package:prestigeconsult/ui/screens/features/evaluation_vente/evaluation_vente_screen.dart';
import 'package:prestigeconsult/ui/screens/features/fiche_article/fiche_article_screen.dart';
import 'package:prestigeconsult/ui/screens/features/recherche_article/recherche_article_screen.dart';
import 'package:prestigeconsult/ui/screens/features/update_peremption/update_peremption_screen.dart';
import 'package:prestigeconsult/ui/screens/home/home_screen.dart';
import 'package:prestigeconsult/ui/screens/features/orders/order_receiving_screen.dart';
import 'package:prestigeconsult/ui/screens/features/orders/order_list_screen.dart';
import 'package:prestigeconsult/ui/screens/features/stock_entry/delivery_slip_list_screen.dart';


class AppRoutes {
  static const String login = '/login';
  static const String settings = '/settings';
  static const String home = '/home';

  // Routes pour les fonctionnalités
  static const String ficheArticle = '/fiche-article';
  static const String evaluationVente = '/evaluation-vente';
  static const String rechercheArticle = '/recherche-article';
  static const String updatePeremption = '/update-peremption';
  static const String orderList = '/order-list';
  static const String orderReceiving = '/order-receiving';
  static const String deliverySlipList = '/delivery-slip-list';

  static final Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    settings: (context) => const SettingsScreen(),
    home: (context) => const HomeScreen(),

    // Ajout des nouvelles routes
    ficheArticle: (context) => const FicheArticleScreen(),
    evaluationVente: (context) => const EvaluationVenteScreen(),
    rechercheArticle: (context) => const RechercheArticleScreen(),
    updatePeremption: (context) => const UpdatePeremptionScreen(),
    orderList: (context) => const OrderListScreen(),
    deliverySlipList: (context) => const DeliverySlipListScreen(),
    // orderReceiving: (context) => const OrderReceivingScreen(), // On le mettra en place à la prochaine étape
  };
}