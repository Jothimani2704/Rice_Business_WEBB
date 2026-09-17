import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_strings.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language_code';
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;
  bool get isTamil => _currentLanguage == 'ta';

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_languageKey);
    if (savedLang != null && (savedLang == 'en' || savedLang == 'ta')) {
      _currentLanguage = savedLang;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String langCode) async {
    if (_currentLanguage == langCode) return;
    _currentLanguage = langCode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, langCode);
  }

  Future<void> toggleLanguage() async {
    final newLang = _currentLanguage == 'en' ? 'ta' : 'en';
    await setLanguage(newLang);
  }

  String tr(String key) {
    return AppStrings.get(key, _currentLanguage);
  }
}
