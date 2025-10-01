import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';
import '../../models/models.dart';
import '../../services/nfc_service.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/connectivity_service.dart';
import '../../core/constants.dart';

// Events
abstract class NfcEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class NfcStartReading extends NfcEvent {
  final String sessionId;

  NfcStartReading({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

class NfcStopReading extends NfcEvent {}

class NfcCardDetected extends NfcEvent {
  final String cardId;

  NfcCardDetected({required this.cardId});

  @override
  List<Object?> get props => [cardId];
}

class NfcSyncPending extends NfcEvent {}

// States
abstract class NfcState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NfcInitial extends NfcState {}

class NfcReading extends NfcState {
  final String sessionId;
  final int checkInCount;
  final List<CheckInResponse> recentCheckIns;

  NfcReading({
    required this.sessionId,
    this.checkInCount = 0,
    this.recentCheckIns = const [],
  });

  @override
  List<Object?> get props => [sessionId, checkInCount, recentCheckIns];

  NfcReading copyWith({
    int? checkInCount,
    List<CheckInResponse>? recentCheckIns,
  }) {
    return NfcReading(
      sessionId: sessionId,
      checkInCount: checkInCount ?? this.checkInCount,
      recentCheckIns: recentCheckIns ?? this.recentCheckIns,
    );
  }
}

class NfcCheckInSuccess extends NfcState {
  final CheckInResponse checkIn;

  NfcCheckInSuccess({required this.checkIn});

  @override
  List<Object?> get props => [checkIn];
}

class NfcCheckInError extends NfcState {
  final String message;
  final String? errorCode;

  NfcCheckInError({required this.message, this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

class NfcStopped extends NfcState {}

class NfcError extends NfcState {
  final String message;

  NfcError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class NfcBloc extends Bloc<NfcEvent, NfcState> {
  final NfcService _nfcService;
  final ApiService _apiService;
  final StorageService _storageService;
  final ConnectivityService _connectivityService;

  StreamSubscription<NfcReadResult>? _nfcSubscription;
  Timer? _syncTimer;

  final _uuid = const Uuid();

  NfcBloc({
    required NfcService nfcService,
    required ApiService apiService,
    required StorageService storageService,
    required ConnectivityService connectivityService,
  })  : _nfcService = nfcService,
        _apiService = apiService,
        _storageService = storageService,
        _connectivityService = connectivityService,
        super(NfcInitial()) {
    on<NfcStartReading>(_onStartReading);
    on<NfcStopReading>(_onStopReading);
    on<NfcCardDetected>(_onCardDetected);
    on<NfcSyncPending>(_onSyncPending);
  }

  Future<void> _onStartReading(
    NfcStartReading event,
    Emitter<NfcState> emit,
  ) async {
    try {
      // Check if NFC is available
      final isAvailable = await _nfcService.isAvailable();
      if (!isAvailable) {
        emit(NfcError(message: 'NFC not available on this device'));
        return;
      }

      emit(NfcReading(sessionId: event.sessionId));

      // Start NFC reading
      _nfcSubscription = _nfcService.startReading().listen(
        (result) {
          if (result.success && result.cardId != null) {
            add(NfcCardDetected(cardId: result.cardId!));
          } else if (result.errorMessage != null) {
            // Don't emit error for every failed read, just log it
            print('NFC read error: ${result.errorMessage}');
          }
        },
        onError: (error) {
          add(NfcStopReading());
          emit(NfcError(message: 'NFC reading error: $error'));
        },
      );

      // Start periodic sync for offline check-ins
      _startPeriodicSync();
    } catch (e) {
      emit(NfcError(message: 'Failed to start NFC reading: $e'));
    }
  }

  Future<void> _onStopReading(
    NfcStopReading event,
    Emitter<NfcState> emit,
  ) async {
    await _nfcSubscription?.cancel();
    _nfcSubscription = null;

    _syncTimer?.cancel();
    _syncTimer = null;

    await _nfcService.stopReading();

    emit(NfcStopped());
  }

  Future<void> _onCardDetected(
    NfcCardDetected event,
    Emitter<NfcState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NfcReading) return;

    try {
      // Vibrate on card detection if enabled
      if (_storageService.getVibrationEnabled()) {
        await Vibration.vibrate(duration: 100);
      }

      final deviceId = await _storageService.getOrCreateDeviceId();
      final isOnline = _connectivityService.isOnline;

      // Create attendance log
      final log = AttendanceLog(
        id: _uuid.v4(),
        sessionId: currentState.sessionId,
        studentId: '', // Will be filled by backend
        nfcCardId: event.cardId,
        timestamp: DateTime.now(),
        wasOffline: !isOnline,
        status: AttendanceLogStatus.valid.value,
        deviceId: deviceId,
        appVersion: AppConstants.appVersion,
        syncStatus: isOnline ? 'syncing' : 'pending',
      );

      if (isOnline) {
        // Try immediate sync
        final response = await _apiService.checkIn(
          sessionId: currentState.sessionId,
          nfcCardId: event.cardId,
          timestamp: log.timestamp,
          deviceId: deviceId,
          appVersion: AppConstants.appVersion,
        );

        if (response.success && response.data != null) {
          // Success - vibrate twice
          if (_storageService.getVibrationEnabled()) {
            await Future.delayed(const Duration(milliseconds: 100));
            await Vibration.vibrate(duration: 50);
          }

          // Update check-in count
          final updatedState = currentState.copyWith(
            checkInCount: currentState.checkInCount + 1,
            recentCheckIns: [response.data!, ...currentState.recentCheckIns]
                .take(10)
                .toList(),
          );

          emit(updatedState);
          emit(NfcCheckInSuccess(checkIn: response.data!));
          emit(updatedState);
        } else {
          // Failed - save to offline queue
          await _storageService.addPendingCheckIn(log);

          emit(NfcCheckInError(
            message: response.error ?? 'Check-in failed',
            errorCode: response.errorCode,
          ));

          // Return to reading state
          emit(currentState);
        }
      } else {
        // Offline - save to queue
        await _storageService.addPendingCheckIn(log);

        // Optimistic UI update
        final updatedState = currentState.copyWith(
          checkInCount: currentState.checkInCount + 1,
        );

        emit(updatedState);
        emit(NfcCheckInSuccess(
          checkIn: CheckInResponse(
            logId: log.id,
            studentName: 'Offline Check-in',
            studentId: event.cardId,
            checkInTime: log.timestamp,
            status: 'pending',
          ),
        ));
        emit(updatedState);
      }
    } catch (e) {
      emit(NfcCheckInError(message: 'Error processing check-in: $e'));
      emit(currentState);
    }
  }

  Future<void> _onSyncPending(
    NfcSyncPending event,
    Emitter<NfcState> emit,
  ) async {
    if (!_connectivityService.isOnline) return;

    final pendingLogs = _storageService.getPendingCheckIns();
    if (pendingLogs.isEmpty) return;

    print('Syncing ${pendingLogs.length} pending check-ins...');

    // Convert to JSON format for batch sync
    final checkIns = pendingLogs
        .map((log) => {
              'id': log.id,
              'session_id': log.sessionId,
              'nfc_card_id': log.nfcCardId,
              'timestamp': log.timestamp.toIso8601String(),
              'latitude': log.latitude,
              'longitude': log.longitude,
              'accuracy': log.accuracy,
              'device_id': log.deviceId,
              'app_version': log.appVersion,
            })
        .toList();

    try {
      final response = await _apiService.batchSync(checkIns: checkIns);

      if (response.success && response.data != null) {
        // Process results
        for (final result in response.data!) {
          final localId = result['local_id'];

          if (result['success'] == true) {
            // Remove from pending queue
            await _storageService.removePendingCheckIn(localId);
            print('Synced check-in: $localId');
          } else {
            // Mark as failed
            await _storageService.updateCheckInStatus(
              logId: localId,
              syncStatus: 'failed',
            );
            print('Failed to sync: $localId - ${result['error']}');
          }
        }
      }
    } catch (e) {
      print('Batch sync error: $e');
    }
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(
      AppConstants.syncRetryInterval,
      (_) {
        add(NfcSyncPending());
      },
    );
  }

  @override
  Future<void> close() {
    _nfcSubscription?.cancel();
    _syncTimer?.cancel();
    return super.close();
  }
}
