class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://api.attendance.edu'; // Mock for now
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String deviceIdKey = 'device_id';

  // Hive Boxes
  static const String pendingCheckInsBox = 'pending_checkins';
  static const String sessionCacheBox = 'session_cache';
  static const String userCacheBox = 'user_cache';

  // NFC Configuration
  static const Duration nfcReadTimeout = Duration(seconds: 5);
  static const int nfcRetryAttempts = 3;
  static const Duration nfcRetryDelay = Duration(milliseconds: 500);

  // Offline Sync
  static const Duration syncRetryInterval = Duration(seconds: 30);
  static const int maxPendingSyncRecords = 1000;
  static const Duration offlineBatchSyncDelay = Duration(seconds: 2);

  // Session Defaults
  static const Duration defaultSessionDuration = Duration(hours: 2);
  static const Duration sessionWarningThreshold = Duration(minutes: 15);

  // UI Configuration
  static const Duration toastDuration = Duration(seconds: 3);
  static const Duration successAnimationDuration = Duration(milliseconds: 500);
  static const Duration vibrationDuration = Duration(milliseconds: 100);

  // Validation
  static const int minPasswordLength = 8;
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  // App Version
  static const String appVersion = '1.0.0';
  static const String appName = 'Smart Attendance';
}

class ApiEndpoints {
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  static const String userProfile = '/users/me';
  static const String courses = '/courses';

  static const String sessions = '/sessions';
  static String sessionDetail(String id) => '/sessions/$id';
  static String closeSession(String id) => '/sessions/$id/close';
  static String sessionAttendance(String id) => '/sessions/$id/attendance';

  static const String checkIn = '/attendance/checkin';
  static const String batchSync = '/attendance/batch-sync';

  static String courseDetail(String id) => '/courses/$id';
}

enum UserRole {
  student,
  lecturer,
  admin;

  String get value => name.toUpperCase();
}

enum SessionStatus {
  active,
  closed,
  cancelled;

  String get value => name.toUpperCase();
}

enum AttendanceLogStatus {
  valid,
  flagged,
  invalid;

  String get value => name.toUpperCase();
}

enum SyncStatus {
  pending,
  syncing,
  synced,
  failed;
}
