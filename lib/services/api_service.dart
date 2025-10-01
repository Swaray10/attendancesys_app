import 'dart:async';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../core/constants.dart';

/// Mock API Service - Simulates backend responses
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _initializeMockData(); // moved init here
  }

  final _uuid = const Uuid();
  final _random = Random();

  // Mock authentication tokens
  String? _accessToken;
  String? _refreshToken;
  User? _currentUser;

  // Mock database
  final List<Course> _mockCourses = [];
  final List<AttendanceSession> _mockSessions = [];
  final List<AttendanceLog> _mockLogs = [];
  final Map<String, User> _mockStudents = {}; // NFC Card ID -> Student

  void _initializeMockData() {
    // Create mock lecturer
    _currentUser = User(
      id: _uuid.v4(),
      email: 'lecturer@university.edu',
      firstName: 'John',
      lastName: 'Smith',
      role: UserRole.lecturer.value,
      isActive: true,
      createdAt: DateTime.now(),
    );

    // Create mock courses
    _mockCourses.addAll([
      Course(
        id: _uuid.v4(),
        code: 'CS101',
        name: 'Introduction to Programming',
        description: 'Basic programming concepts using Python',
        semester: 'Fall 2025',
        year: 2025,
        lecturerId: _currentUser!.id,
        isActive: true,
      ),
      Course(
        id: _uuid.v4(),
        code: 'CS201',
        name: 'Data Structures and Algorithms',
        description: 'Core data structures and algorithmic techniques',
        semester: 'Fall 2025',
        year: 2025,
        lecturerId: _currentUser!.id,
        isActive: true,
      ),
      Course(
        id: _uuid.v4(),
        code: 'CS301',
        name: 'Database Systems',
        description: 'Relational databases and SQL',
        semester: 'Fall 2025',
        year: 2025,
        lecturerId: _currentUser!.id,
        isActive: true,
      ),
    ]);

    // Create mock students with NFC cards
    final studentNames = [
      ['Alice', 'Johnson'],
      ['Bob', 'Williams'],
      ['Carol', 'Davis'],
      ['David', 'Miller'],
      ['Emma', 'Wilson'],
      ['Frank', 'Moore'],
      ['Grace', 'Taylor'],
      ['Henry', 'Anderson'],
    ];

    for (var i = 0; i < studentNames.length; i++) {
      final nfcId = _generateMockNfcId();
      final student = User(
        id: _uuid.v4(),
        email:
            '${studentNames[i][0].toLowerCase()}.${studentNames[i][1].toLowerCase()}@student.edu',
        firstName: studentNames[i][0],
        lastName: studentNames[i][1],
        studentId: '2025${(1000 + i).toString()}',
        nfcCardId: nfcId,
        role: UserRole.student.value,
        isActive: true,
        createdAt: DateTime.now(),
      );
      _mockStudents[nfcId] = student;
    }
  }

  String _generateMockNfcId() {
    final bytes = List.generate(7, (_) => _random.nextInt(256));
    return bytes
        .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join(':');
  }

  /// Simulate network delay
  Future<void> _simulateDelay({int minMs = 100, int maxMs = 500}) async {
    final delay = minMs + _random.nextInt(maxMs - minMs);
    await Future.delayed(Duration(milliseconds: delay));
  }

  // ============ AUTHENTICATION ============

  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    await _simulateDelay();

    if (email == 'lecturer@university.edu' && password == 'password123') {
      _accessToken = _uuid.v4();
      _refreshToken = _uuid.v4();

      return ApiResponse(
        success: true,
        data: {
          'access_token': _accessToken,
          'refresh_token': _refreshToken,
          'user': _currentUser!.toJson(),
        },
      );
    }

    return ApiResponse(
      success: false,
      error: 'Invalid credentials',
      errorCode: 'INVALID_CREDENTIALS',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> refreshToken(
      String refreshToken) async {
    await _simulateDelay(minMs: 50, maxMs: 150);

    if (refreshToken == _refreshToken) {
      _accessToken = _uuid.v4();

      return ApiResponse(
        success: true,
        data: {
          'access_token': _accessToken,
        },
      );
    }

    return ApiResponse(
      success: false,
      error: 'Invalid refresh token',
      errorCode: 'INVALID_REFRESH_TOKEN',
    );
  }

  Future<ApiResponse<void>> logout() async {
    await _simulateDelay(minMs: 50, maxMs: 100);

    _accessToken = null;
    _refreshToken = null;

    return ApiResponse(success: true);
  }

  // ============ USER ============

  Future<ApiResponse<User>> getCurrentUser() async {
    await _simulateDelay();

    if (_currentUser != null) {
      return ApiResponse(success: true, data: _currentUser);
    }

    return ApiResponse(
      success: false,
      error: 'Not authenticated',
      errorCode: 'UNAUTHORIZED',
    );
  }

  // ============ COURSES ============

  Future<ApiResponse<List<Course>>> getCourses() async {
    await _simulateDelay();

    return ApiResponse(
      success: true,
      data: List.from(_mockCourses),
    );
  }

  Future<ApiResponse<Course>> getCourse(String courseId) async {
    await _simulateDelay();

    final course = _mockCourses.firstWhere(
      (c) => c.id == courseId,
      orElse: () => throw Exception('Course not found'),
    );

    return ApiResponse(success: true, data: course);
  }

  // ============ SESSIONS ============

  Future<ApiResponse<AttendanceSession>> createSession({
    required String courseId,
    required String sessionType,
    String? location,
    int? autoCloseDuration,
  }) async {
    await _simulateDelay();

    final course = _mockCourses.firstWhere((c) => c.id == courseId);
    final now = DateTime.now();

    final session = AttendanceSession(
      id: _uuid.v4(),
      courseId: courseId,
      createdById: _currentUser!.id,
      startTime: now,
      location: location,
      sessionType: sessionType,
      autoCloseAt: autoCloseDuration != null
          ? now.add(Duration(minutes: autoCloseDuration))
          : null,
      status: SessionStatus.active.value,
      requiresPhoto: false,
      checkInCount: 0,
      course: course,
    );

    _mockSessions.add(session);

    return ApiResponse(success: true, data: session);
  }

  Future<ApiResponse<List<AttendanceSession>>> getSessions() async {
    await _simulateDelay();

    return ApiResponse(
      success: true,
      data: List.from(_mockSessions),
    );
  }

  Future<ApiResponse<AttendanceSession>> getSession(String sessionId) async {
    await _simulateDelay();

    final session = _mockSessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw Exception('Session not found'),
    );

    return ApiResponse(success: true, data: session);
  }

  Future<ApiResponse<AttendanceSession>> closeSession(String sessionId) async {
    await _simulateDelay();

    final index = _mockSessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) {
      return ApiResponse(
        success: false,
        error: 'Session not found',
        errorCode: 'SESSION_NOT_FOUND',
      );
    }

    final session = _mockSessions[index];
    final updatedSession = session.copyWith(
      status: SessionStatus.closed.value,
      endTime: DateTime.now(),
    );

    _mockSessions[index] = updatedSession;

    return ApiResponse(success: true, data: updatedSession);
  }

  // ============ ATTENDANCE ============

  Future<ApiResponse<CheckInResponse>> checkIn({
    required String sessionId,
    required String nfcCardId,
    required DateTime timestamp,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? deviceId,
    String? appVersion,
  }) async {
    await _simulateDelay();

    final session = _mockSessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw Exception('Session not found'),
    );

    if (session.status != SessionStatus.active.value) {
      return ApiResponse(
        success: false,
        error: 'Session is not active',
        errorCode: 'SESSION_NOT_ACTIVE',
      );
    }

    final student = _mockStudents[nfcCardId];
    if (student == null) {
      return ApiResponse(
        success: false,
        error: 'Card not registered',
        errorCode: 'CARD_NOT_REGISTERED',
      );
    }

    final existingLog = _mockLogs.firstWhere(
      (log) => log.sessionId == sessionId && log.studentId == student.id,
      orElse: () => AttendanceLog(
        id: '',
        sessionId: '',
        studentId: '',
        nfcCardId: '',
        timestamp: DateTime.now(),
        wasOffline: false,
        status: '',
      ),
    );

    if (existingLog.id.isNotEmpty) {
      return ApiResponse(
        success: false,
        error: 'Student already checked in',
        errorCode: 'ALREADY_CHECKED_IN',
      );
    }

    final log = AttendanceLog(
      id: _uuid.v4(),
      sessionId: sessionId,
      studentId: student.id,
      nfcCardId: nfcCardId,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      wasOffline: false,
      syncedAt: DateTime.now(),
      status: AttendanceLogStatus.valid.value,
      deviceId: deviceId,
      appVersion: appVersion,
      syncStatus: 'synced',
    );

    _mockLogs.add(log);

    final sessionIndex = _mockSessions.indexWhere((s) => s.id == sessionId);
    _mockSessions[sessionIndex] = session.copyWith(
      checkInCount: session.checkInCount + 1,
    );

    return ApiResponse(
      success: true,
      data: CheckInResponse(
        logId: log.id,
        studentName: student.fullName,
        studentId: student.studentId!,
        checkInTime: timestamp,
        status: 'valid',
      ),
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> batchSync({
    required List<Map<String, dynamic>> checkIns,
  }) async {
    await _simulateDelay(minMs: 200, maxMs: 800);

    final results = <Map<String, dynamic>>[];

    for (final entry in checkIns) {
      final result = await checkIn(
        sessionId: entry['session_id'],
        nfcCardId: entry['nfc_card_id'],
        timestamp: DateTime.parse(entry['timestamp']),
        latitude: entry['latitude'],
        longitude: entry['longitude'],
        accuracy: entry['accuracy'],
        deviceId: entry['device_id'],
        appVersion: entry['app_version'],
      );

      results.add({
        'local_id': entry['id'],
        'success': result.success,
        'log_id': result.data?.logId,
        'error': result.error,
      });
    }

    return ApiResponse(success: true, data: results);
  }

  Future<ApiResponse<List<AttendanceLog>>> getSessionAttendance(
      String sessionId) async {
    await _simulateDelay();

    final logs = _mockLogs.where((log) => log.sessionId == sessionId).toList();

    return ApiResponse(success: true, data: logs);
  }

  // ============ UTILITY ============

  bool isAuthenticated() => _accessToken != null;

  User? get currentUser => _currentUser;

  Map<String, User> get mockStudents => _mockStudents;
}
