import 'package:flutter/material.dart';

class AppTheme {
  // Light Mode Colors
  static const Color _lightBackground = Color(0xFFF2F2F7);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _primaryBlue = Color(0xFF007AFF);

  // Dark Mode Colors
  static const Color _darkBackground = Color(0xFF000000);
  static const Color _darkCard = Color(0xFF1C1C1E);
  static const Color _primaryDarkBlue = Color(0xFF0A84FF);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackground,
      primaryColor: _primaryBlue,
      cardColor: _lightCard,
      fontFamily: '.SF Pro Text',
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 34,
          fontWeight: FontWeight.bold,
        ),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackground,
      primaryColor: _primaryDarkBlue,
      cardColor: _darkCard,
      fontFamily: '.SF Pro Text',
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.bold,
        ),
      ),
      useMaterial3: true,
    );
  }
}