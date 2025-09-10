import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Colors.teal;
  static const Color secondary = Color(0xFF26A69A); // Un teal plus clair
  static const Color accent = Color(0xFF00796B);   // Un teal plus foncé
  static const Color background = Color(0xFFF5F5F5);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Colors.white;
}

class AppStyles {
  static const TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
  static const TextStyle dataLabelStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.accent,
  );
  static const TextStyle dataValueStyle = TextStyle(
    fontSize: 16,
    color: AppColors.textDark,
  );
}