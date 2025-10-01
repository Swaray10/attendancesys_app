import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _connectivityStreamController;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  bool _isOnline = true;

  /// Get current connectivity status
  bool get isOnline => _isOnline;

  /// Initialize and start monitoring connectivity
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);

    // Start monitoring
    startMonitoring();
  }

  /// Start monitoring connectivity changes
  void startMonitoring() {
    if (_connectivityStreamController != null) return;

    _connectivityStreamController = StreamController<bool>.broadcast();

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        final wasOnline = _isOnline;
        _isOnline = _isConnected(result);

        // Only emit if status changed
        if (wasOnline != _isOnline) {
          _connectivityStreamController?.add(_isOnline);
        }
      },
    );
  }

  /// Get connectivity status stream
  Stream<bool> get connectivityStream {
    if (_connectivityStreamController == null) {
      startMonitoring();
    }
    return _connectivityStreamController!.stream;
  }

  /// Check if connectivity result indicates online status
  bool _isConnected(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;
  }

  /// Manually check connectivity (useful for retry logic)
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);
    return _isOnline;
  }

  /// Stop monitoring
  void stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivityStreamController?.close();
    _connectivitySubscription = null;
    _connectivityStreamController = null;
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}
