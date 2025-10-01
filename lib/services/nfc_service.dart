import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  static final NfcService _instance = NfcService._internal();
  factory NfcService() => _instance;
  NfcService._internal();

  StreamController<NfcReadResult>? _nfcStreamController;
  bool _isReading = false;

  /// Check if device supports NFC
  Future<bool> isAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Start continuous NFC reading session
  Stream<NfcReadResult> startReading() {
    if (_isReading) return _nfcStreamController!.stream;

    _nfcStreamController = StreamController<NfcReadResult>.broadcast();
    _isReading = true;

    _startNfcSession();

    return _nfcStreamController!.stream;
  }

  void _startNfcSession() async {
    try {
      // Stop any previous session
      await NfcManager.instance.stopSession();

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) {
          final cardId = _extractCardId(tag);
          if (cardId != null) {
            _nfcStreamController?.add(
              NfcReadResult.success(cardId: cardId, rawData: _castTagData(tag)),
            );
          } else {
            _nfcStreamController?.add(
              NfcReadResult.error(message: 'Unable to read card ID'),
            );
          }
        },
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
      );
    } catch (e) {
      _nfcStreamController?.add(
        NfcReadResult.error(message: 'NFC Error: $e'),
      );
    }
  }

  /// Extract NFC card UID from tag data
  String? _extractCardId(NfcTag tag) {
    try {
      final data = _castTagData(tag);
      debugPrint('Raw NFC tag data: $data');


      if (data.containsKey('nfca')) {
        final id = List<int>.from(data['nfca']['identifier']);
        return _formatCardId(id);
      }
      if (data.containsKey('nfcb')) {
        final id = List<int>.from(data['nfcb']['identifier']);
        return _formatCardId(id);
      }
      if (data.containsKey('isodep')) {
        final id = List<int>.from(data['isodep']['identifier']);
        return _formatCardId(id);
      }
      if (data.containsKey('nfcf')) {
        final id = List<int>.from(data['nfcf']['identifier']);
        return _formatCardId(id);
      }
      if (data.containsKey('nfcv')) {
        final id = List<int>.from(data['nfcv']['identifier']);
        return _formatCardId(id);
      }

      return null;
    } catch (e) {
      debugPrint('Error extracting card ID: $e');
      return null;
    }
  }

  /// Safely cast tag.data to Map<String, dynamic>
  Map<String, dynamic> _castTagData(NfcTag tag) {
    final data = tag.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {};
  }

  /// Format card ID as hex string
  String _formatCardId(List<int> identifier) {
    return identifier
        .map((byte) => byte.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join(':');
  }

  /// One-shot NFC read
  Future<NfcReadResult> readSingleTag({Duration timeout = const Duration(seconds: 5)}) async {
    final completer = Completer<NfcReadResult>();
    Timer? timer;

    try {
      timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          NfcManager.instance.stopSession();
          completer.complete(NfcReadResult.error(message: 'Read timeout'));
        }
      });

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) {
          if (!completer.isCompleted) {
            final cardId = _extractCardId(tag);
            if (cardId != null) {
              completer.complete(NfcReadResult.success(cardId: cardId, rawData: _castTagData(tag)));
            } else {
              completer.complete(NfcReadResult.error(message: 'Unable to read card ID'));
            }
            NfcManager.instance.stopSession();
          }
        },
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
      );

      return completer.future;
    } catch (e) {
      return NfcReadResult.error(message: 'Failed to start NFC session: $e');
    } finally {
      timer?.cancel();
    }
  }

  /// Stop NFC reading session
  Future<void> stopReading() async {
    if (!_isReading) return;

    try {
      await NfcManager.instance.stopSession();
      _isReading = false;
      await _nfcStreamController?.close();
      _nfcStreamController = null;
    } catch (e) {
      debugPrint('Error stopping NFC session: $e');
    }
  }

  bool get isReading => _isReading;

  void dispose() => stopReading();
}

/// NFC Read Result
class NfcReadResult {
  final bool success;
  final String? cardId;
  final Map<String, dynamic>? rawData;
  final String? errorMessage;

  NfcReadResult._({required this.success, this.cardId, this.rawData, this.errorMessage});

  factory NfcReadResult.success({required String cardId, Map<String, dynamic>? rawData}) {
    return NfcReadResult._(success: true, cardId: cardId, rawData: rawData);
  }

  factory NfcReadResult.error({required String message}) {
    return NfcReadResult._(success: false, errorMessage: message);
  }

  @override
  String toString() => success ? 'NfcReadResult.success(cardId: $cardId)' : 'NfcReadResult.error(message: $errorMessage)';
}
