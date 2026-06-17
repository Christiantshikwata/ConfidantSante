import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Hachage des mots de passe (SHA-256 + sel lié à l'identité).
///
/// Le sel est l'identifiant unique de l'utilisateur (numéro de téléphone pour
/// un patient, matricule pour un soignant). Cela évite de stocker un sel
/// séparé tout en empêchant deux utilisateurs ayant le même mot de passe
/// d'obtenir le même hachage.
class PasswordService {
  static const String _pepper = 'confidantsante_v1';

  /// Retourne le hachage hexadécimal du mot de passe.
  static String hash({required String identifiant, required String motDePasse}) {
    final donnees = utf8.encode('$identifiant:$_pepper:$motDePasse');
    return sha256.convert(donnees).toString();
  }

  /// Vérifie qu'un mot de passe en clair correspond au hachage stocké.
  static bool verifier({
    required String identifiant,
    required String motDePasse,
    required String hachageStocke,
  }) {
    return hash(identifiant: identifiant, motDePasse: motDePasse) == hachageStocke;
  }
}
