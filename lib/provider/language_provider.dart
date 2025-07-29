// lib/providers/language_provider.dart
import 'package:flutter/foundation.dart';
import '../models/book_model.dart';

class LanguageProvider extends ChangeNotifier {
  Language _selectedLanguage = Language.indonesia;

  Language get selectedLanguage => _selectedLanguage;

  void setLanguage(Language language) {
    _selectedLanguage = language;
    notifyListeners();
  }
}