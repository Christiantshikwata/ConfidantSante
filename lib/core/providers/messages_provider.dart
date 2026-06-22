import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';

/// Notifications de messagerie en temps réel, SANS backend.
///
/// Tant que l'app tourne (y compris quand l'utilisateur est sur une autre
/// page), ce provider écoute les conversations de l'utilisateur via les
/// `snapshots()` Firestore. À chaque message entrant (émis par l'autre partie),
/// si l'utilisateur n'est pas en train de lire ce fil, il déclenche une
/// notification locale et incrémente le compteur de messages non lus (badge).
///
/// Le « lu » est suivi par un horodatage `lastSeen` par conversation, persisté
/// localement — les badges survivent donc au redémarrage de l'app.
class MessagesProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _subs = {};
  final Map<String, int> _nonLus = {};
  final Map<String, String> _noms = {};
  final Map<String, DateTime> _lastSeen = {};
  final Map<String, bool> _premierSnapshot = {};

  String? _monId;
  String? _conversationActive;
  int _notifId = 90000;

  bool get firebaseDisponible => SyncService().firebaseDisponible;

  /// Total des messages non lus (toutes conversations).
  int get totalNonLus => _nonLus.values.fold(0, (a, b) => a + b);

  /// Non-lus d'une conversation précise.
  int nonLusPour(String conversationId) => _nonLus[conversationId] ?? 0;

  CollectionReference<Map<String, dynamic>> _col(String convId) =>
      FirebaseFirestore.instance
          .collection('conversations')
          .doc(convId)
          .collection('messages');

  /// Démarre/actualise l'écoute pour l'ensemble des conversations de
  /// l'utilisateur. [conversations] associe chaque conversationId au nom à
  /// afficher dans la notification (médecin pour un patient, patient pour un
  /// soignant). Idempotent : peut être rappelé quand la liste évolue.
  Future<void> demarrer({
    required String monId,
    required Map<String, String> conversations,
  }) async {
    if (!firebaseDisponible) return;
    _monId = monId;

    // Annule les abonnements devenus inutiles.
    for (final id in _subs.keys.toList()) {
      if (!conversations.containsKey(id)) {
        await _subs[id]?.cancel();
        _subs.remove(id);
        _nonLus.remove(id);
      }
    }

    for (final entry in conversations.entries) {
      _noms[entry.key] = entry.value;
      if (_subs.containsKey(entry.key)) continue;
      _premierSnapshot[entry.key] = true;
      _lastSeen[entry.key] = await _lireLastSeen(entry.key);
      _subs[entry.key] = _col(entry.key)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen((snap) => _surSnapshot(entry.key, snap));
    }
    notifyListeners();
  }

  void _surSnapshot(
      String convId, QuerySnapshot<Map<String, dynamic>> snap) {
    final actif = _conversationActive == convId;
    final reference = actif
        ? DateTime.now()
        : (_lastSeen[convId] ?? DateTime.fromMillisecondsSinceEpoch(0));

    // Recompte les non-lus (messages de l'autre, postérieurs à lastSeen).
    int count = 0;
    for (final d in snap.docs) {
      final data = d.data();
      final exp = data['expediteur_id']?.toString() ?? '';
      final ts = (data['timestamp'] as Timestamp?)?.toDate();
      if (exp != _monId && ts != null && ts.isAfter(reference)) count++;
    }

    // Notifications pour les nouveaux messages (hors 1er chargement et hors
    // conversation actuellement ouverte).
    final premier = _premierSnapshot[convId] ?? false;
    if (!premier && !actif) {
      for (final change in snap.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null) continue;
        final exp = data['expediteur_id']?.toString() ?? '';
        final ts = (data['timestamp'] as Timestamp?)?.toDate();
        if (exp != _monId && ts != null && ts.isAfter(reference)) {
          NotificationService().afficherMessage(
            id: _notifId++,
            titre: _noms[convId] ?? 'Nouveau message',
            corps: data['texte'] as String? ?? '',
          );
        }
      }
    }
    _premierSnapshot[convId] = false;

    _nonLus[convId] = actif ? 0 : count;
    notifyListeners();
  }

  /// À appeler à l'ouverture d'une conversation : la marque comme active et lue.
  Future<void> ouvrirConversation(String conversationId) async {
    _conversationActive = conversationId;
    _lastSeen[conversationId] = DateTime.now();
    _nonLus[conversationId] = 0;
    await _ecrireLastSeen(conversationId);
    notifyListeners();
  }

  /// À appeler à la fermeture de la conversation.
  Future<void> fermerConversation() async {
    final id = _conversationActive;
    if (id != null) {
      _lastSeen[id] = DateTime.now();
      await _ecrireLastSeen(id);
    }
    _conversationActive = null;
    notifyListeners();
  }

  /// Stoppe toutes les écoutes (déconnexion).
  Future<void> arreter() async {
    for (final s in _subs.values) {
      await s.cancel();
    }
    _subs.clear();
    _nonLus.clear();
    _noms.clear();
    _premierSnapshot.clear();
    _conversationActive = null;
    _monId = null;
    notifyListeners();
  }

  Future<DateTime> _lireLastSeen(String convId) async {
    final s = await _storage.read(key: 'lastseen_$convId');
    return DateTime.tryParse(s ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _ecrireLastSeen(String convId) async {
    await _storage.write(
      key: 'lastseen_$convId',
      value: DateTime.now().toIso8601String(),
    );
  }

  @override
  void dispose() {
    for (final s in _subs.values) {
      s.cancel();
    }
    super.dispose();
  }
}
