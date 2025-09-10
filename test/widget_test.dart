// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:prestigeconsult/main.dart';
import 'package:prestigeconsult/providers/app_config_provider.dart';

void main() {
  testWidgets('App starts and displays login or settings screen', (WidgetTester tester) async {
    // --- Phase de Préparation (Setup) ---

    // 1. On crée une instance du provider dont notre application dépend.
    final appConfigProvider = AppConfigProvider();

    // 2. On charge sa configuration initiale, exactement comme on le fait dans main.dart.
    // C'est une étape cruciale car la logique de MyApp dépend de l'état de ce provider.
    await appConfigProvider.loadConfig();

    // --- Phase d'Exécution (Act) ---

    // 3. On construit notre application et on déclenche le rendu d'une image.
    // On passe ici le provider requis par le widget MyApp.
    await tester.pumpWidget(MyApp(appConfigProvider: appConfigProvider));

    // --- Phase de Vérification (Assert) ---

    // 4. On vérifie que le titre de l'application 'PrestigeConsult' est présent.
    // Cela confirme que l'application a démarré et affiche soit l'écran de connexion,
    // soit l'écran de configuration, qui contiennent tous deux des références au nom de l'app.
    // Note: find.text() est sensible à la casse.
    expect(find.text('PrestigeConsult'), findsOneWidget);

    // Le test de compteur par défaut n'est plus pertinent pour notre application.
    // On le laisse en commentaire pour référence.
    /*
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    */
  });
}