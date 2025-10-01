import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

// Events
abstract class SessionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SessionLoadRequested extends SessionEvent {}

class SessionCreateRequested extends SessionEvent {
  final String courseId;
  final String sessionType;
  final String? location;
  final int? autoCloseDuration;

  SessionCreateRequested({
    required this.courseId,
    this.sessionType = 'lecture',
    this.location,
    this.autoCloseDuration,
  });

  @override
  List<Object?> get props =>
      [courseId, sessionType, location, autoCloseDuration];
}

class SessionCloseRequested extends SessionEvent {
  final String sessionId;

  SessionCloseRequested({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

class SessionCheckInCountUpdated extends SessionEvent {
  final String sessionId;
  final int newCount;

  SessionCheckInCountUpdated({
    required this.sessionId,
    required this.newCount,
  });

  @override
  List<Object?> get props => [sessionId, newCount];
}

// States
abstract class SessionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SessionInitial extends SessionState {}

class SessionLoading extends SessionState {}

class SessionsLoaded extends SessionState {
  final List<AttendanceSession> sessions;
  final AttendanceSession? activeSession;

  SessionsLoaded({
    required this.sessions,
    this.activeSession,
  });

  @override
  List<Object?> get props => [sessions, activeSession];
}

class SessionCreated extends SessionState {
  final AttendanceSession session;

  SessionCreated({required this.session});

  @override
  List<Object?> get props => [session];
}

class SessionClosed extends SessionState {
  final AttendanceSession session;

  SessionClosed({required this.session});

  @override
  List<Object?> get props => [session];
}

class SessionError extends SessionState {
  final String message;

  SessionError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final ApiService _apiService;

  SessionBloc({required ApiService apiService})
      : _apiService = apiService,
        super(SessionInitial()) {
    on<SessionLoadRequested>(_onLoadRequested);
    on<SessionCreateRequested>(_onCreateRequested);
    on<SessionCloseRequested>(_onCloseRequested);
    on<SessionCheckInCountUpdated>(_onCheckInCountUpdated);
  }

  Future<void> _onLoadRequested(
    SessionLoadRequested event,
    Emitter<SessionState> emit,
  ) async {
    emit(SessionLoading());

    try {
      final response = await _apiService.getSessions();

      if (response.success && response.data != null) {
        final sessions = response.data!;
        final activeSession = sessions.firstWhere(
          (s) => s.isActive,
          orElse: () => sessions.first,
        );

        emit(SessionsLoaded(
          sessions: sessions,
          activeSession: activeSession.isActive ? activeSession : null,
        ));
      } else {
        emit(
            SessionError(message: response.error ?? 'Failed to load sessions'));
      }
    } catch (e) {
      emit(SessionError(message: 'Error loading sessions: $e'));
    }
  }

  Future<void> _onCreateRequested(
    SessionCreateRequested event,
    Emitter<SessionState> emit,
  ) async {
    emit(SessionLoading());

    try {
      final response = await _apiService.createSession(
        courseId: event.courseId,
        sessionType: event.sessionType,
        location: event.location,
        autoCloseDuration: event.autoCloseDuration,
      );

      if (response.success && response.data != null) {
        emit(SessionCreated(session: response.data!));

        // Reload sessions to update list
        add(SessionLoadRequested());
      } else {
        emit(SessionError(
            message: response.error ?? 'Failed to create session'));
      }
    } catch (e) {
      emit(SessionError(message: 'Error creating session: $e'));
    }
  }

  Future<void> _onCloseRequested(
    SessionCloseRequested event,
    Emitter<SessionState> emit,
  ) async {
    try {
      final response = await _apiService.closeSession(event.sessionId);

      if (response.success && response.data != null) {
        emit(SessionClosed(session: response.data!));

        // Reload sessions
        add(SessionLoadRequested());
      } else {
        emit(
            SessionError(message: response.error ?? 'Failed to close session'));
      }
    } catch (e) {
      emit(SessionError(message: 'Error closing session: $e'));
    }
  }

  Future<void> _onCheckInCountUpdated(
    SessionCheckInCountUpdated event,
    Emitter<SessionState> emit,
  ) async {
    final currentState = state;

    if (currentState is SessionsLoaded) {
      final updatedSessions = currentState.sessions.map((session) {
        if (session.id == event.sessionId) {
          return session.copyWith(checkInCount: event.newCount);
        }
        return session;
      }).toList();

      final updatedActiveSession = currentState.activeSession?.id ==
              event.sessionId
          ? currentState.activeSession!.copyWith(checkInCount: event.newCount)
          : currentState.activeSession;

      emit(SessionsLoaded(
        sessions: updatedSessions,
        activeSession: updatedActiveSession,
      ));
    }
  }
}
