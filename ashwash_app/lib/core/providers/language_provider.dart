import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  static const String langKey = 'app_language';
  String _currentLanguage = 'en'; // 'en' or 'bn'

  String get currentLanguage => _currentLanguage;
  bool get isBangla => _currentLanguage == 'bn';

  LanguageProvider() {
    _loadLanguageFromStorage();
  }

  Future<void> _loadLanguageFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(langKey) ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    if (_currentLanguage != langCode) {
      _currentLanguage = langCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(langKey, langCode);
      notifyListeners();
    }
  }

  void toggleLanguage() {
    setLanguage(_currentLanguage == 'en' ? 'bn' : 'en');
  }
}
