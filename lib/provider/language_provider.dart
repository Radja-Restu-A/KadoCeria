import 'package:flutter/foundation.dart';
import '../models/book_model.dart';

class LanguageProvider extends ChangeNotifier {
  Language _selectedLanguage = Language.indonesia;

  Language get selectedLanguage => _selectedLanguage;

  void setLanguage(Language language) {
    try{
      _selectedLanguage = language;
      notifyListeners();
    }catch (e){
      throw Exception('Failed to set language: $e');
    }
  }
}