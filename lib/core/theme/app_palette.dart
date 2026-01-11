import 'package:flutter/material.dart';

class AppPalette {
  static const thinking = Color(0xFF6B5A73);
  static const reading = Color(0xFF5E6F66);
  static const daily = Color(0xFF8C6A3A);

  static const dictionaryGeneral = Color(0xFF5C6F82);
  static const dictionaryTech = Color(0xFF5F6F5C);
  static const dictionaryEnglish = Color(0xFF7B664E);

  static Color soften(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount) ?? color;
  }
}
