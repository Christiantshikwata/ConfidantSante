
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class IconService {

  static final IconService _instance = IconService._internal();
  factory IconService() => _instance;
  IconService._internal();

  // Canal de communication Flutter ↔ Android natif
  static const MethodChannel _channel =
  MethodChannel('cd.udbl.fsi.confidantsante/icon');

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Noms des alias Android (doivent correspondre à AndroidManifest.xml)
  static const Map<String, String> _aliases = {
    'normal':       'cd.udbl.fsi.confidantsante.MainActivityDefault',
    'calculatrice': 'cd.udbl.fsi.confidantsante.MainActivityCalculatrice',
    'meteo':        'cd.udbl.fsi.confidantsante.MainActivityMeteo',
    'notes':        'cd.udbl.fsi.confidantsante.MainActivityNotes',
    'minuteur':     'cd.udbl.fsi.confidantsante.MainActivityMinuteur',
  };

  /// Change l'icône de l'app dans le launcher Android
  /// [apparence] : 'normal' | 'calculatrice' | 'meteo' | 'notes' | 'minuteur'
  Future<bool> changerIcone(String apparence) async {
    try {
      final alias = _aliases[apparence];
      if (alias == null) return false;

      final result = await _channel.invokeMethod<bool>(
        'changerIcone',
        {'alias': alias},
      );

      if (result == true) {
        // Sauvegarde l'apparence active
        await _storage.write(key: 'apparence_active', value: apparence);
        await _storage.write(
          key: 'camouflage_actif',
          value: apparence != 'normal' ? 'true' : 'false',
        );
      }

      return result ?? false;
    } on PlatformException catch (e) {
      // Sur certains appareils, le changement d'icône est bloqué
      // On sauvegarde quand même la préférence pour la façade interne
      await _storage.write(key: 'apparence_active', value: apparence);
      await _storage.write(
        key: 'camouflage_actif',
        value: apparence != 'normal' ? 'true' : 'false',
      );
      return false;
    }
  }

  /// Récupère l'apparence actuellement active
  Future<String> getApparenceActive() async {
    return await _storage.read(key: 'apparence_active') ?? 'normal';
  }

  /// Vérifie si le camouflage est actif
  Future<bool> isCamouflageActif() async {
    final val = await _storage.read(key: 'camouflage_actif');
    return val == 'true';
  }

  /// Désactive le camouflage et revient à l'icône normale
  Future<void> desactiverCamouflage() async {
    await changerIcone('normal');
  }
}