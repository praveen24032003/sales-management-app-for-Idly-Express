import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme controller for managing app theme (light/dark/system)
class ThemeController extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode';
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  ThemeController() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getString(_themeModeKey);
    final loadedMode = switch (storedValue) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    if (_mode != loadedMode) {
      _mode = loadedMode;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode newMode) async {
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final value = switch (newMode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await prefs.setString(_themeModeKey, value);
    }
  }
}
