import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prestigeconsult/core/config/app_config.dart';
import 'package:prestigeconsult/core/logic/base_screen_logic.dart';
import 'package:prestigeconsult/models/officine.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';
import 'package:prestigeconsult/providers/auth_provider.dart';
import 'package:prestigeconsult/core/api/api_service.dart';
import 'package:prestigeconsult/utils/app_routes.dart';
import 'package:shimmer/shimmer.dart';

// Définition d'un modèle simple pour les items du menu
class MenuItem {
  final String title;
  final IconData icon;
  final String route;

  MenuItem({required this.title, required this.icon, required this.route});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with BaseScreenLogic {
  final ApiService _apiService = ApiService();
  Officine? _officine;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Liste de toutes les fonctionnalités de l'application
  final List<MenuItem> _menuItems = [
    MenuItem(title: 'Fiche Article', icon: Icons.article, route: AppRoutes.ficheArticle),
    MenuItem(title: 'Évaluation Ventes', icon: Icons.bar_chart, route: AppRoutes.evaluationVente),
    MenuItem(title: 'Recherche & Historique', icon: Icons.search, route: AppRoutes.rechercheArticle),
    MenuItem(title: 'Mise à Jour Péremption', icon: Icons.date_range, route: AppRoutes.updatePeremption),
    MenuItem(title: 'Réception Commandes', icon: Icons.inventory, route: AppRoutes.orderList),
    MenuItem(title: 'Contrôle Stock', icon: Icons.fact_check, route: AppRoutes.deliverySlipList),
    // Ajoutez de nouveaux menus ici
  ];

  // Paramètre pour le nombre de menus par page
  final int _itemsPerPage = 6;

  @override
  void initState() {
    super.initState();
    // Charge les données de la pharmacie au chargement de l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOfficineData();
    });

    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (_currentPage != page) {
        setState(() {
          _currentPage = page;
        });
      }
    });
  }

  Future<void> _loadOfficineData() async {
    final configProvider = Provider.of<AppConfigProvider>(context, listen: false);
    final response = await runApiCall(() => _apiService.get('/officine', configProvider));

    if (response != null && response is List && response.isNotEmpty) {
      setState(() {
        _officine = Officine.fromJson(response.first);
      });
    }
  }

  void _handleLogout() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final configProvider = Provider.of<AppConfigProvider>(context, listen: false);
    authProvider.logout(configProvider);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AppRoutes.routes[AppRoutes.login]!(context)),
          (route) => false, // Supprime toutes les routes précédentes
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadOfficineData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWelcomeCard(authProvider.user?.firstName, _officine?.nomComplet),
              const SizedBox(height: 24),
              const Text('Fonctionnalités', style: AppStyles.titleStyle),
              const SizedBox(height: 16),
              _buildMenu(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: isLoading
          ? Shimmer.fromColors(
        baseColor: Colors.white70,
        highlightColor: Colors.white,
        child: Container(width: 150, height: 20, color: Colors.white),
      )
          : Text(_officine?.nomComplet ?? 'PrestigeConsult'),
      backgroundColor: AppColors.primary,
      actions: [
        // Switch pour le mode de connexion
        Consumer<AppConfigProvider>(
          builder: (context, config, child) => IconButton(
            icon: Icon(config.connectionMode == ConnectionMode.local ? Icons.home : Icons.public),
            tooltip: 'Mode ${config.connectionMode == ConnectionMode.local ? 'Local' : 'Distant'}',
            onPressed: () {
              final newMode = config.connectionMode == ConnectionMode.local
                  ? ConnectionMode.distant
                  : ConnectionMode.local;
              config.setConnectionMode(newMode);
            },
          ),
        ),
        // Menu d'options (Paramètres, Déconnexion)
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'settings') {
              Navigator.pushNamed(context, AppRoutes.settings);
            } else if (value == 'logout') {
              _handleLogout();
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Text('Paramètres'),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Text('Se déconnecter'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(String? userName, String? drName) {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(height: 80, width: double.infinity, color: Colors.white, margin: const EdgeInsets.only(bottom: 16)),
      );
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bienvenu(e) ${userName ?? ''}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text(drName ?? 'Chargement...', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    // Calcule le nombre de pages nécessaires
    final pageCount = (_menuItems.length / _itemsPerPage).ceil();

    return Column(
      children: [
        SizedBox(
          height: 250, // Hauteur fixe pour le menu
          child: PageView.builder(
            controller: _pageController,
            itemCount: pageCount,
            itemBuilder: (context, index) {
              final startIndex = index * _itemsPerPage;
              final endIndex = (startIndex + _itemsPerPage > _menuItems.length)
                  ? _menuItems.length
                  : startIndex + _itemsPerPage;
              final pageItems = _menuItems.sublist(startIndex, endIndex);
              return _buildMenuGrid(pageItems);
            },
          ),
        ),
        if (pageCount > 1) _buildPageIndicator(pageCount),
      ],
    );
  }

  Widget _buildMenuGrid(List<MenuItem> items) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(), // Le scroll est géré par PageView
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 colonnes
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, item.route),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 40, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator(int pageCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        return Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? AppColors.primary
                : Colors.grey.withOpacity(0.5),
          ),
        );
      }),
    );
  }
}