import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {

  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Vérifie si l'appareil supporte la biométrie
  Future<bool> isDisponible() async {
    try {
      return await _auth.canCheckBiometrics &&
          await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Vérifie les types de biométrie disponibles
  Future<List<BiometricType>> getTypesDisponibles() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Authentification biométrique
  Future<bool> authentifier({String raison = 'Confirmez votre identité'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: raison,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // false = permet PIN système si biométrie échoue
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == 'NotEnrolled' || e.code == 'NotAvailable') {
        return false;
      }
      return false;
    }
  }

  /// Retourne l'icône selon le type de biométrie disponible
  Future<String> getTypeBiometrie() async {
    final types = await getTypesDisponibles();
    if (types.contains(BiometricType.face)) return 'face';
    if (types.contains(BiometricType.fingerprint)) return 'fingerprint';
    return 'none';
  }
}
