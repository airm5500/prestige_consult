import 'package:flutter/material.dart';
import 'package:prestigeconsult/core/config/app_config.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData? icon;
  final bool isPassword;
  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: icon != null ? Icon(icon, color: AppColors.primary) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ce champ ne peut pas être vide';
        }
        return null;
      },
    );
  }
}