import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'is_dark_mode';
  bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider({bool initialDarkMode = false}) : _isDarkMode = initialDarkMode;

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, value);
    } catch (e) {
      debugPrint('Failed to save theme preference: $e');
    }
  }
}
