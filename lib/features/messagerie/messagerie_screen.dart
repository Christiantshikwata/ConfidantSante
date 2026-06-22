// lib/features/messagerie/messagerie_screen.dart
// ConfidantSanté — Messagerie temps réel via Firestore (offline-first).
// Repli automatique sur SQLite local si Firebase n'est pas disponible.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/messages_provider.dart';
import '../../core/services/database_service.dart';
import '../../core/services/sync_service.dart';

class MessagerieScreen extends StatefulWidget {
  /// Identifiant de conversation STABLE entre appareils.
  final String conversationId;

  /// Identité stable de l'utilisateur courant (numéro patient ou matricule soignant).
  final String monId;

  final String destinataireNom;
  final String role; // 'patient' ou 'soignant'

  const MessagerieScreen({
    super.key,
    required this.conversationId,
    required this.monId,
    required this.destinataireNom,
    required this.role,
  });

  /// Construit un identifiant de conversation stable, identique des deux côtés.
  static String conversationIdPour({
    required String patientNumero,
    required String soignantMatricule,
  }) =>
      '${patientNumero}__$soignantMatricule';

  @override
  State<MessagerieScreen> createState() => _MessagerieScreenState();
}

class _MessagerieScreenState extends State<MessagerieScreen> {

  final TextEditingController _msgCtrl  = TextEditingController();
  final ScrollController      _scrollCtrl = ScrollController();

  late final bool _useFirestore = SyncService().firebaseDisponible;

  // Mode local uniquement
  bool _isLoading = true;
  List<Map<String, dynamic>> _messagesLocaux = [];

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('conversations')
      .doc(widget.conversationId)
      .collection('messages');

  MessagesProvider? _messagesProvider;

  @override
  void initState() {
    super.initState();
    if (!_useFirestore) _chargerLocaux();
    // Marque la conversation comme active/lue (suspend ses notifications/badge).
    _messagesProvider = context.read<MessagesProvider>();
    _messagesProvider?.ouvrirConversation(widget.conversationId);
  }

  @override
  void dispose() {
    _messagesProvider?.fermerConversation();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerLocaux() async {
    final msgs = await DatabaseService().getMessages(widget.conversationId);
    if (mounted) {
      setState(() {
        _messagesLocaux = msgs;
        _isLoading = false;
      });
      _scrollerBas();
    }
  }

  Future<void> _envoyerMessage() async {
    final texte = _msgCtrl.text.trim();
    if (texte.isEmpty) return;
    _msgCtrl.clear();

    if (_useFirestore) {
      await _col.add({
        'expediteur_id':   widget.monId,
        'expediteur_role': widget.role,
        'texte':           texte,
        'timestamp':       FieldValue.serverTimestamp(),
      });
      _scrollerBas();
    } else {
      await DatabaseService().envoyerMessage(
        conversationId: widget.conversationId,
        expediteurId:   widget.monId,
        expediteurRole: widget.role,
        destinataireId: '',
        texte:          texte,
      );
      await _chargerLocaux();
    }
  }

  void _scrollerBas() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final couleurHeader = widget.role == 'soignant'
        ? const Color(0xFF0288D1)
        : AppColors.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [
          _entete(couleurHeader),
          Expanded(child: _zoneMessages()),
          _zoneSaisie(couleurHeader),
        ],
      ),
    );
  }

  // ── En-tête ─────────────────────────────────────────────────────────────
  Widget _entete(Color couleurHeader) {
    return Container(
      decoration: BoxDecoration(
        color: couleurHeader,
        borderRadius: const BorderRadius.only(
          bottomLeft:  Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.destinataireNom
                        .split(' ')
                        .map((e) => e.isNotEmpty ? e[0] : '')
                        .take(2)
                        .join()
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.destinataireNom,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.role == 'patient' ? 'Soignant — CHCC' : 'Patient',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge mode
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _useFirestore
                          ? Icons.cloud_done_outlined
                          : Icons.storage_outlined,
                      color: Colors.white,
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _useFirestore ? 'En ligne' : 'Local',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Zone messages ─────────────────────────────────────────────────────────
  Widget _zoneMessages() {
    if (_useFirestore) {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _col.orderBy('timestamp', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return _vide();
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollerBas());
          return ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data();
              return _bulleDepuis(
                texte: d['texte'] as String? ?? '',
                expediteurId: d['expediteur_id']?.toString() ?? '',
                role: d['expediteur_role'] as String? ?? '',
                timestamp: (d['timestamp'] as Timestamp?)?.toDate(),
              );
            },
          );
        },
      );
    }

    // Mode local
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_messagesLocaux.isEmpty) return _vide();
    return RefreshIndicator(
      onRefresh: _chargerLocaux,
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        itemCount: _messagesLocaux.length,
        itemBuilder: (_, i) {
          final m = _messagesLocaux[i];
          return _bulleDepuis(
            texte: m['texte'] as String? ?? '',
            expediteurId: m['expediteur_id']?.toString() ?? '',
            role: m['expediteur_role'] as String? ?? '',
            timestamp: DateTime.tryParse(m['timestamp'] as String? ?? ''),
          );
        },
      ),
    );
  }

  Widget _bulleDepuis({
    required String texte,
    required String expediteurId,
    required String role,
    required DateTime? timestamp,
  }) {
    String heure = '';
    if (timestamp != null) {
      heure =
          '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    return _BulleMessage(
      texte: texte,
      heure: heure,
      estMoi: expediteurId == widget.monId,
      role: role,
    );
  }

  // ── Zone saisie ─────────────────────────────────────────────────────────
  Widget _zoneSaisie(Color couleurHeader) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        // Le Scaffold (resizeToAvoidBottomInset) remonte déjà le corps au-dessus
        // du clavier : on ne rajoute donc PAS viewInsets.bottom (sinon double
        // comptage → « Bottom overflowed »). On garde seulement la safe-area.
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE0E7EF)),
              ),
              child: TextField(
                controller: _msgCtrl,
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Écrivez un message...',
                  hintStyle: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _envoyerMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _envoyerMessage,
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: couleurHeader,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vide() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'Aucun message pour l\'instant.\nCommencez la conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      );
}

// ── Bulle de message ─────────────────────────────────────────────────────────
class _BulleMessage extends StatelessWidget {
  final String texte, heure, role;
  final bool estMoi;

  const _BulleMessage({
    required this.texte,
    required this.heure,
    required this.estMoi,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            estMoi ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!estMoi) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: role == 'soignant'
                    ? const Color(0xFF0288D1)
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                role == 'soignant'
                    ? Icons.medical_services_outlined
                    : Icons.person_outline,
                color: Colors.white, size: 14,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: estMoi ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: estMoi
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: estMoi
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    texte,
                    style: TextStyle(
                      fontSize: 14,
                      color: estMoi ? Colors.white : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    heure,
                    style: TextStyle(
                      fontSize: 10,
                      color: estMoi
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
