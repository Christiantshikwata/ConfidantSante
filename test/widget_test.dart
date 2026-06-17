// Tests unitaires du service de hachage des mots de passe.
// (L'ancien smoke test du splash dépendait de plugins natifs et d'un timer
//  non résolus en environnement de test ; il est remplacé ici.)

import 'package:flutter_test/flutter_test.dart';
import 'package:confidantsante/core/services/password_service.dart';

void main() {
  group('PasswordService', () {
    test('le hachage est déterministe pour la même entrée', () {
      final h1 = PasswordService.hash(identifiant: '812345678', motDePasse: 'secret1');
      final h2 = PasswordService.hash(identifiant: '812345678', motDePasse: 'secret1');
      expect(h1, equals(h2));
    });

    test('le hachage n\'est jamais le mot de passe en clair', () {
      final h = PasswordService.hash(identifiant: '812345678', motDePasse: 'secret1');
      expect(h, isNot(equals('secret1')));
      expect(h.length, equals(64)); // SHA-256 hexadécimal
    });

    test('le même mot de passe donne des hachages différents selon l\'identité', () {
      final h1 = PasswordService.hash(identifiant: '811111111', motDePasse: 'pareil');
      final h2 = PasswordService.hash(identifiant: '822222222', motDePasse: 'pareil');
      expect(h1, isNot(equals(h2)));
    });

    test('verifier accepte le bon mot de passe et rejette un mauvais', () {
      final h = PasswordService.hash(identifiant: 'MED-2024-001', motDePasse: 'soignant123');
      expect(
        PasswordService.verifier(
          identifiant: 'MED-2024-001',
          motDePasse: 'soignant123',
          hachageStocke: h,
        ),
        isTrue,
      );
      expect(
        PasswordService.verifier(
          identifiant: 'MED-2024-001',
          motDePasse: 'mauvais',
          hachageStocke: h,
        ),
        isFalse,
      );
    });
  });
}
