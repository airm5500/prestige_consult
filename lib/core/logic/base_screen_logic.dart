import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Un "mixin" est une façon de réutiliser le code d'une classe dans plusieurs hiérarchies de classes.
// Ici, on l'applique à un State<T> d'un StatefulWidget.
mixin BaseScreenLogic<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _errorMessage;

  // Getters pour que l'UI puisse accéder à ces états
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Méthode helper pour exécuter un appel API en toute sécurité
  // Elle prend en paramètre la fonction qui fait l'appel réel.
  Future<R?> runApiCall<R>(Future<R> Function() apiRequest, {bool showToastOnError = true}) async {
    // Si un chargement est déjà en cours, on ne fait rien.
    if (_isLoading) return null;

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Réinitialise les erreurs précédentes
    });

    try {
      // Exécute la fonction d'appel API et retourne son résultat
      final result = await apiRequest();
      return result;
    } catch (e) {
      final errorText = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorMessage = errorText; // Stocke le message d'erreur
      });
      if (showToastOnError) {
        Fluttertoast.showToast(msg: errorText);
      }
      return null; // Retourne null en cas d'erreur
    } finally {
      // Quoi qu'il arrive (succès ou erreur), on arrête le chargement.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}