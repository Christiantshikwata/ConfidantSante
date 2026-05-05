import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Gère la session de l'utilisateur connecté
class SessionService {

  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Sauvegarde la session après connexion
  Future<void> sauvegarderSession({
    required String patientId,
    required String nom,
    required String numero,
  }) async {
    await _storage.write(key: 'patient_id', value: patientId);
    await _storage.write(key: 'patient_nom', value: nom);
    await _storage.write(key: 'patient_numero', value: numero);
    await _storage.write(key: 'connecte', value: 'true');
  }

  // Récupère l'ID du patient connecté
  Future<String?> getPatientId() async {
    return await _storage.read(key: 'patient_id');
  }

  // Récupère le nom du patient connecté
  Future<String?> getNom() async {
    return await _storage.read(key: 'patient_nom');
  }

  // Récupère le numéro du patient connecté
  Future<String?> getNumero() async {
    return await _storage.read(key: 'patient_numero');
  }

  // Vérifie si quelqu'un est connecté
  Future<bool> estConnecte() async {
    final val = await _storage.read(key: 'connecte');
    return val == 'true';
  }

  // Déconnecte l'utilisateur
  Future<void> deconnecter() async {
    await _storage.deleteAll();
  }

  // Sauvegarde le PIN
  Future<void> sauvegarderPin(String pin) async {
    await _storage.write(key: 'pin', value: pin);
  }

  // Vérifie le PIN
  Future<bool> verifierPin(String pin) async {
    final pinSauvegarde = await _storage.read(key: 'pin');
    return pinSauvegarde == pin;
  }

  // Vérifie si le PIN est configuré
  Future<bool> pinConfigue() async {
    final pin = await _storage.read(key: 'pin');
    return pin != null && pin.isNotEmpty;
  }
}