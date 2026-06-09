
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/app_colors.dart';
import '../services/sync_service.dart';

class SyncBadge extends StatefulWidget {
  const SyncBadge({super.key});

  @override
  State<SyncBadge> createState() => _SyncBadgeState();
}

class _SyncBadgeState extends State<SyncBadge> {
  bool _connecte = false;
  bool _enSync = false;
  String _dernierMessage = '';

  @override
  void initState() {
    super.initState();
    _verifierConnexion();
  }

  Future<void> _verifierConnexion() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => _connecte = result != ConnectivityResult.none);
    }
  }

  Future<void> _syncMaintenant() async {
    if (_enSync) return;
    setState(() => _enSync = true);

    final result = await SyncService().synchroniser();

    if (mounted) {
      setState(() {
        _enSync = false;
        _dernierMessage = result.message;
        _connecte = result.succes || _connecte;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                result.succes
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                color: Colors.white, size: 16,
              ),
              const SizedBox(width: 8),
              Text(result.message),
            ],
          ),
          backgroundColor: result.succes
              ? AppColors.success
              : AppColors.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _syncMaintenant,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_enSync)
              const SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 1.5,
                ),
              )
            else
              Icon(
                _connecte
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                color: Colors.white,
                size: 14,
              ),
            const SizedBox(width: 5),
            Text(
              _enSync
                  ? 'Sync...'
                  : _connecte
                  ? 'Synchronisé'
                  : 'Hors ligne',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}