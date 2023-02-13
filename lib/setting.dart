import 'package:flutter/material.dart';

class GameSettings {
  static const double blurRadius = 50;
  static BorderRadius borderRadius = BorderRadius.circular(32);
  static String formatVersion = '2';
  static double Perfect2 = 0.03,
      Perect = 0.06,
      Good = 0.12,
      Bad = 0.135,
      Valid = 0.15,
      HoldValid = 0.3;

  static LinearGradient gradient = const LinearGradient(
    colors: [
      Color(0xffbec8ff),
      Color(0xffcfe3ff),
    ],
    begin: Alignment(0, 0),
    end: Alignment(1, 1),
  );
}
