import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../l10n/app_translations.dart';

class LangueProvider extends ChangeNotifier {

  String _code = 'fr';
  String get code => _code;

  // Charge la langue sauvegardée au démarrage
  Future<void> charger() async {
    final code = await SessionService().getLangue();
    _code = code;
    AppTranslations.changerLangue(code);
    notifyListeners();
  }

  // Change la langue et notifie tous les widgets
  Future<void> changerLangue(String code) async {
    _code = code;
    AppTranslations.changerLangue(code);
    await SessionService().sauvegarderLangue(code);
    notifyListeners();
  }

  // Raccourci pour traduire
  String t(String cle) => AppTranslations.t(cle);
}