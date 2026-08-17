import 'package:flutter/material.dart';
import 'translations.dart';

class AppLanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;
  bool get isBangla => _currentLanguage == 'bn';

  void setLanguage(String langCode) {
    if (_currentLanguage != langCode) {
      _currentLanguage = langCode;
      notifyListeners();
    }
  }

  void toggleLanguage() {
    _currentLanguage = (_currentLanguage == 'en') ? 'bn' : 'en';
    notifyListeners();
  }

  String translate(String key) {
    return Translations.get(key, _currentLanguage);
  }
}
