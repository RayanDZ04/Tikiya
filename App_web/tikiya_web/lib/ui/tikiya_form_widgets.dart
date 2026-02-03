import 'package:flutter/material.dart';

import 'tikiya_colors.dart';

class TikiyaLabel extends StatelessWidget {
  final String text;

  const TikiyaLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: TikiyaColors.grisFonce,
          fontSize: 16,
          letterSpacing: 0.01,
        ),
      ),
    );
  }
}

class TikiyaTextField extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;

  const TikiyaTextField({
    super.key,
    required this.controller,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          filled: true,
          fillColor: TikiyaColors.fondInput,
          contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: TikiyaColors.grisClair),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: TikiyaColors.grisClair),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: TikiyaColors.bleuCyan),
          ),
        ),
        style: const TextStyle(color: TikiyaColors.grisFonce, fontSize: 16),
      ),
    );
  }
}
