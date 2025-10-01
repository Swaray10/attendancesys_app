import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../core/constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Box<AttendanceLog> _pendingCheckInsBox;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  /// Initialize storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(AttendanceLogAdapter());

    // Open boxes
    _pendingCheckInsBox = await Hive.openBox<AttendanceLog>(
      AppConstants.pendingCheckInsBox,
    );

    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    _isInitialized = true;
  }

  // ============ TOKEN MANAGEMENT ============

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(AppConstants.accessTokenKey, accessToken);
    await _prefs.setString(AppConstants.refreshTokenKey, refreshToken);
  }

  String? getAccessToken() {
    return _prefs.getString(AppConstants.accessTokenKey);
  }

  String? getRefreshToken() {
    return _prefs.getString(AppConstants.refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _prefs.remove(AppConstants.accessTokenKey);
    await _prefs.remove(AppConstants.refreshTokenKey);
  }

  // ============ USER DATA ============

  Future<void> saveUserData(String userData) async {
    await _prefs.setString(AppConstants.userDataKey, userData);
  }

  String? getUserData() {
    return _prefs.getString(AppConstants.userDataKey);
  }

  Future<void> clearUserData() async {
    await _prefs.remove(AppConstants.userDataKey);
  }

  // ============ DEVICE ID ============

  Future<String> getOrCreateDeviceId() async {
    String? deviceId = _prefs.getString(AppConstants.deviceIdKey);

    if (deviceId == null) {
      deviceId = 'flutter-device-${DateTime.now().millisecondsSinceEpoch}';
      await _prefs.setString(AppConstants.deviceIdKey, deviceId);
    }

    return deviceId;
  }

  // ============ PENDING CHECK-INS (OFFLINE QUEUE) ============

  /// Add check-in to offline queue
  Future<void> addPendingCheckIn(AttendanceLog log) async {
    await _pendingCheckInsBox.put(log.id, log);
  }

  /// Get all pending check-ins
  List<AttendanceLog> getPendingCheckIns() {
    return _pendingCheckInsBox.values.toList();
  }

  /// Get pending check-ins count
  int getPendingCount() {
    return _pendingCheckInsBox.length;
  }

  /// Update check-in sync status
  Future<void> updateCheckInStatus({
    required String logId,
    required String syncStatus,
    DateTime? syncedAt,
  }) async {
    final log = _pendingCheckInsBox.get(logId);
    if (log != null) {
      final updated = log.copyWith(
        syncStatus: syncStatus,
        syncedAt: syncedAt,
      );
      await _pendingCheckInsBox.put(logId, updated);
    }
  }

  /// Remove synced check-in from queue
  Future<void> removePendingCheckIn(String logId) async {
    await _pendingCheckInsBox.delete(logId);
  }

  /// Clear all synced check-ins
  Future<void> clearSyncedCheckIns() async {
    final toRemove = <String>[];

    for (final log in _pendingCheckInsBox.values) {
      if (log.syncStatus == 'synced') {
        toRemove.add(log.id);
      }
    }

    for (final id in toRemove) {
      await _pendingCheckInsBox.delete(id);
    }
  }

  /// Clear all pending check-ins
  Future<void> clearAllPendingCheckIns() async {
    await _pendingCheckInsBox.clear();
  }

  // ============ APP SETTINGS ============

  Future<void> setSetting(String key, dynamic value) async {
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    }
  }

  T? getSetting<T>(String key) {
    return _prefs.get(key) as T?;
  }

  // Sound settings
  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setBool('sound_enabled', enabled);
  }

  bool getSoundEnabled() {
    return _prefs.getBool('sound_enabled') ?? true;
  }

  // Vibration settings
  Future<void> setVibrationEnabled(bool enabled) async {
    await _prefs.setBool('vibration_enabled', enabled);
  }

  bool getVibrationEnabled() {
    return _prefs.getBool('vibration_enabled') ?? true;
  }

  // ============ CLEANUP ============

  Future<void> clearAll() async {
    await _pendingCheckInsBox.clear();
    await _prefs.clear();
  }

  void dispose() {
    _pendingCheckInsBox.close();
  }
}

// Note: You'll need to generate the Hive adapter by running:
// flutter packages pub run build_runner build
