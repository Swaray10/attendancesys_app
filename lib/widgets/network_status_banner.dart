import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/connectivity_service.dart';
import '../services/storage_service.dart';

class NetworkStatusBanner extends StatefulWidget {
  const NetworkStatusBanner({super.key});

  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends State<NetworkStatusBanner> {
  final _connectivityService = ConnectivityService();
  final _storageService = StorageService();

  bool _isOnline = true;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _isOnline = _connectivityService.isOnline;
    _pendingCount = _storageService.getPendingCount();

    // Listen to connectivity changes
    _connectivityService.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
          if (isOnline) {
            // Update pending count when back online
            _pendingCount = _storageService.getPendingCount();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline && _pendingCount == 0) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.md,
        vertical: AppTheme.sm,
      ),
      color: _isOnline ? AppTheme.warningColor : AppTheme.errorColor,
      child: Row(
        children: [
          Icon(
            _isOnline ? Icons.sync : Icons.wifi_off,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: AppTheme.sm),
          Expanded(
            child: Text(
              _isOnline
                  ? 'Syncing $_pendingCount pending check-in${_pendingCount != 1 ? 's' : ''}...'
                  : 'Offline - Check-ins will sync when online',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
