// lib/features/messagerie/messagerie_screen.dart
// ConfidantSanté — Messagerie locale SQLite (offline-first)
// Remplace la version Firestore — fonctionne sans internet

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/database_service.dart';
import '../../core/services/session_service.dart';

class MessagerieScreen extends StatefulWidget {
  final String destinataireId;
  final String destinataireNom;
  final String role; // 'patient' ou 'soignant'

  const MessagerieScreen({
    super.key,
    required this.destinataireId,
    required this.destinataireNom,
    required this.role,
  });

  @override
  State<MessagerieScreen> createState() => _MessagerieScreenState();
}

class _MessagerieScreenState extends State<MessagerieScreen> {

  final TextEditingController _msgCtrl  = TextEditingController();
  final ScrollController      _scrollCtrl = ScrollController();

  String? _monId;
  String? _conversationId;
  bool _isLoading = true;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initialiser();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Initialisation ────────────────────────────────────────────────────────
  Future<void> _initialiser() async {
    if (widget.role == 'patient') {
      _monId = await SessionService().getPatientId();
    } else {
      _monId = await SessionService().getSoignantId();
    }
    if (_monId == null) return;

    // ID de conversation : patientId_soignantId (toujours trié de la même façon)
    final patientId  = widget.role == 'patient' ? _monId! : widget.destinataireId;
    final soignantId = widget.role == 'soignant' ? _monId! : widget.destinataireId;
    _conversationId  = '${patientId}_$soignantId';

    await _chargerMessages();
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Charge les messages depuis SQLite ─────────────────────────────────────
  Future<void> _chargerMessages() async {
    if (_conversationId == null) return;
    final msgs = await DatabaseService().getMessages(_conversationId!);
    if (mounted) {
      setState(() => _messages = msgs);
      _scrollerBas();
    }
  }

  // ── Envoi d'un message ────────────────────────────────────────────────────
  Future<void> _envoyerMessage() async {
    final texte = _msgCtrl.text.trim();
    if (texte.isEmpty || _conversationId == null || _monId == null) return;

    _msgCtrl.clear();

    await DatabaseService().envoyerMessage(
      conversationId:   _conversationId!,
      expediteurId:     _monId!,
      expediteurRole:   widget.role,
      destinataireId:   widget.destinataireId,
      texte:            texte,
    );

    await _chargerMessages();
  }

  void _scrollerBas() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final couleurHeader = widget.role == 'soignant'
        ? const Color(0xFF0288D1)
        : AppColors.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [

          // En-tête
          Container(
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

                    // Avatar initiales
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
                            widget.role == 'patient'
                                ? 'Soignant — CHCC'
                                : 'Patient',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Badge offline
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.storage_outlined,
                              color: Colors.white, size: 11),
                          const SizedBox(width: 4),
                          Text(
                            'Local',
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
          ),

          // Zone messages
          Expanded(
            child: _isLoading
                ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                ? _vide()
                : RefreshIndicator(
              onRefresh: _chargerMessages,
              color: AppColors.primary,
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final msg  = _messages[i];
                  final estMoi = msg['expediteur_id'].toString() == _monId;
                  final ts   = msg['timestamp'] as String? ?? '';
                  String heure = '';
                  if (ts.isNotEmpty) {
                    try {
                      final dt = DateTime.parse(ts);
                      heure =
                      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    } catch (_) {}
                  }
                  return _BulleMessage(
                    texte:   msg['texte'] as String? ?? '',
                    heure:   heure,
                    estMoi:  estMoi,
                    role:    msg['expediteur_role'] as String? ?? '',
                  );
                },
              ),
            ),
          ),

          // Zone saisie
          Container(
            padding: EdgeInsets.only(
              left:   16,
              right:  16,
              top:    12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color:  Colors.black.withValues(alpha: 0.08),
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
                      maxLines:   3,
                      minLines:   1,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Écrivez un message...',
                        hintStyle: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
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
                      color:  couleurHeader,
                      shape:  BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
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
            size: 64,
            color: AppColors.primary.withValues(alpha: 0.3)),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: estMoi ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  estMoi
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: estMoi
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset:     const Offset(0, 2),
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
                      color: estMoi
                          ? Colors.white
                          : AppColors.textPrimary,
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