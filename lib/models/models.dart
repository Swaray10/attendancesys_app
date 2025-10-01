import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'models.g.dart'; // For Hive type adapters

// User Model
class User extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? studentId;
  final String? nfcCardId;
  final String role;
  final String? photoUrl;
  final bool isActive;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.studentId,
    this.nfcCardId,
    required this.role,
    this.photoUrl,
    required this.isActive,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      studentId: json['student_id'],
      nfcCardId: json['nfc_card_id'],
      role: json['role'],
      photoUrl: json['photo_url'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'student_id': studentId,
      'nfc_card_id': nfcCardId,
      'role': role,
      'photo_url': photoUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, email, firstName, lastName, role];
}

// Course Model
class Course extends Equatable {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String semester;
  final int year;
  final String lecturerId;
  final bool isActive;

  const Course({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.semester,
    required this.year,
    required this.lecturerId,
    required this.isActive,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      description: json['description'],
      semester: json['semester'],
      year: json['year'],
      lecturerId: json['lecturer_id'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'semester': semester,
      'year': year,
      'lecturer_id': lecturerId,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [id, code, name];
}

// Attendance Session Model
class AttendanceSession extends Equatable {
  final String id;
  final String courseId;
  final String createdById;
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final String sessionType;
  final DateTime? autoCloseAt;
  final String status;
  final bool requiresPhoto;
  final int checkInCount;
  final Course? course; // Nested course data

  const AttendanceSession({
    required this.id,
    required this.courseId,
    required this.createdById,
    required this.startTime,
    this.endTime,
    this.location,
    required this.sessionType,
    this.autoCloseAt,
    required this.status,
    required this.requiresPhoto,
    this.checkInCount = 0,
    this.course,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isClosed => status == 'CLOSED';

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['id'],
      courseId: json['course_id'],
      createdById: json['created_by_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime:
          json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      location: json['location'],
      sessionType: json['session_type'] ?? 'lecture',
      autoCloseAt: json['auto_close_at'] != null
          ? DateTime.parse(json['auto_close_at'])
          : null,
      status: json['status'],
      requiresPhoto: json['requires_photo'] ?? false,
      checkInCount: json['check_in_count'] ?? 0,
      course: json['course'] != null ? Course.fromJson(json['course']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'created_by_id': createdById,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'location': location,
      'session_type': sessionType,
      'auto_close_at': autoCloseAt?.toIso8601String(),
      'status': status,
      'requires_photo': requiresPhoto,
      'check_in_count': checkInCount,
      if (course != null) 'course': course!.toJson(),
    };
  }

  AttendanceSession copyWith({
    int? checkInCount,
    String? status,
    DateTime? endTime,
  }) {
    return AttendanceSession(
      id: id,
      courseId: courseId,
      createdById: createdById,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      location: location,
      sessionType: sessionType,
      autoCloseAt: autoCloseAt,
      status: status ?? this.status,
      requiresPhoto: requiresPhoto,
      checkInCount: checkInCount ?? this.checkInCount,
      course: course,
    );
  }

  @override
  List<Object?> get props => [id, courseId, startTime, status];
}

// Attendance Log Model
@HiveType(typeId: 0)
class AttendanceLog extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sessionId;

  @HiveField(2)
  final String studentId;

  @HiveField(3)
  final String nfcCardId;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final double? latitude;

  @HiveField(6)
  final double? longitude;

  @HiveField(7)
  final double? accuracy;

  @HiveField(8)
  final String? photoUrl;

  @HiveField(9)
  final bool wasOffline;

  @HiveField(10)
  final DateTime? syncedAt;

  @HiveField(11)
  final String status;

  @HiveField(12)
  final String? flagReason;

  @HiveField(13)
  final String? deviceId;

  @HiveField(14)
  final String? appVersion;

  @HiveField(15)
  final String syncStatus; // pending, syncing, synced, failed

  const AttendanceLog({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.nfcCardId,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.photoUrl,
    required this.wasOffline,
    this.syncedAt,
    required this.status,
    this.flagReason,
    this.deviceId,
    this.appVersion,
    this.syncStatus = 'pending',
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      id: json['id'],
      sessionId: json['session_id'],
      studentId: json['student_id'],
      nfcCardId: json['nfc_card_id'],
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      photoUrl: json['photo_url'],
      wasOffline: json['was_offline'] ?? false,
      syncedAt:
          json['synced_at'] != null ? DateTime.parse(json['synced_at']) : null,
      status: json['status'] ?? 'VALID',
      flagReason: json['flag_reason'],
      deviceId: json['device_id'],
      appVersion: json['app_version'],
      syncStatus: json['sync_status'] ?? 'synced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'student_id': studentId,
      'nfc_card_id': nfcCardId,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'photo_url': photoUrl,
      'was_offline': wasOffline,
      'synced_at': syncedAt?.toIso8601String(),
      'status': status,
      'flag_reason': flagReason,
      'device_id': deviceId,
      'app_version': appVersion,
    };
  }

  AttendanceLog copyWith({
    String? syncStatus,
    DateTime? syncedAt,
  }) {
    return AttendanceLog(
      id: id,
      sessionId: sessionId,
      studentId: studentId,
      nfcCardId: nfcCardId,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      photoUrl: photoUrl,
      wasOffline: wasOffline,
      syncedAt: syncedAt ?? this.syncedAt,
      status: status,
      flagReason: flagReason,
      deviceId: deviceId,
      appVersion: appVersion,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [id, sessionId, studentId, timestamp];
}

// Check-in Response Model
class CheckInResponse extends Equatable {
  final String logId;
  final String studentName;
  final String studentId;
  final DateTime checkInTime;
  final String status;

  const CheckInResponse({
    required this.logId,
    required this.studentName,
    required this.studentId,
    required this.checkInTime,
    required this.status,
  });

  factory CheckInResponse.fromJson(Map<String, dynamic> json) {
    return CheckInResponse(
      logId: json['logId'],
      studentName: json['studentName'],
      studentId: json['studentId'],
      checkInTime: DateTime.parse(json['checkInTime']),
      status: json['status'],
    );
  }

  @override
  List<Object?> get props => [logId, studentId];
}

// API Response Wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? errorCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.errorCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      error: json['error']?['message'],
      errorCode: json['error']?['code'],
    );
  }
}
