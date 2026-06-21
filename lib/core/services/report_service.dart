// lib/core/services/report_service.dart
// ConfidantSanté — Génération de rapports médicaux au format Excel (.xlsx)
// et partage via le menu système.

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_service.dart';

class ReportService {

  String _statut(double obs) {
    if (obs >= 90) return 'Excellent';
    if (obs >= 70) return 'Attention';
    return 'En retard';
  }

  /// Construit le classeur Excel (récap de tous les patients + détail des
  /// prises par patient sur 30 jours) et retourne le chemin du fichier.
  Future<String> genererRapportExcel(
      List<Map<String, dynamic>> patients) async {
    final excel = Excel.createExcel();

    // ── Feuille 1 : Récapitulatif ──────────────────────────────────────────
    final recap = excel['Recapitulatif'];
    recap.appendRow([
      TextCellValue('Nom'),
      TextCellValue('Numero'),
      TextCellValue('Protocole'),
      TextCellValue('Observance (%)'),
      TextCellValue('Statut'),
    ]);
    for (final p in patients) {
      final obs = (p['observance'] as double? ?? 0);
      final traitements =
          await DatabaseService().getTraitements(p['id'] as int);
      final protocole = traitements
          .map((t) => t['nom_medicament'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .join(', ');
      recap.appendRow([
        TextCellValue(p['nom'] as String? ?? ''),
        TextCellValue('+243 ${p['numero'] ?? ''}'),
        TextCellValue(protocole.isEmpty ? '—' : protocole),
        IntCellValue(obs.round()),
        TextCellValue(_statut(obs)),
      ]);
    }

    // ── Feuille 2 : Détail des prises ──────────────────────────────────────
    final det = excel['Details'];
    det.appendRow([
      TextCellValue('Patient'),
      TextCellValue('Numero'),
      TextCellValue('Date'),
      TextCellValue('Statut'),
    ]);
    for (final p in patients) {
      final hist = await DatabaseService().getHistorique30j(p['id'] as int);
      for (final h in hist) {
        final dt = DateTime.tryParse(h['date_heure'] as String? ?? '');
        final dateStr = dt != null
            ? '${dt.day.toString().padLeft(2, '0')}/'
                '${dt.month.toString().padLeft(2, '0')}/${dt.year} '
                '${dt.hour.toString().padLeft(2, '0')}:'
                '${dt.minute.toString().padLeft(2, '0')}'
            : '';
        det.appendRow([
          TextCellValue(p['nom'] as String? ?? ''),
          TextCellValue('${p['numero'] ?? ''}'),
          TextCellValue(dateStr),
          TextCellValue(h['statut'] == 'pris' ? 'Pris' : 'Manque'),
        ]);
      }
    }

    // Retire la feuille par défaut créée automatiquement.
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.save();
    final dir = await getTemporaryDirectory();
    final chemin =
        '${dir.path}/rapport_confidantsante_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(chemin);
    await file.writeAsBytes(bytes ?? <int>[]);
    return chemin;
  }

  /// Génère le rapport puis ouvre le menu de partage du système.
  Future<void> exporterEtPartager(
      List<Map<String, dynamic>> patients) async {
    final chemin = await genererRapportExcel(patients);
    await Share.shareXFiles(
      [XFile(chemin)],
      text: 'Rapport ConfidantSanté',
      subject: 'Rapport d\'observance — ConfidantSanté',
    );
  }
}
