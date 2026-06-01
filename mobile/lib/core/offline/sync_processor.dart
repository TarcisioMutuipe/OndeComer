import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../network/connectivity_service.dart';
import '../network/dio_client.dart';
import 'pending_operation.dart';
import 'sync_queue_service.dart';

const _maxRetries = 3;

// ── State ──────────────────────────────────────────────────────────────────
class SyncState {
  final int pendingCount;
  final bool isSyncing;
  final DateTime? lastSyncAt;
  final String? lastError;

  const SyncState({
    this.pendingCount = 0,
    this.isSyncing = false,
    this.lastSyncAt,
    this.lastError,
  });

  SyncState copyWith({
    int? pendingCount,
    bool? isSyncing,
    DateTime? lastSyncAt,
    String? lastError,
  }) =>
      SyncState(
        pendingCount: pendingCount ?? this.pendingCount,
        isSyncing: isSyncing ?? this.isSyncing,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        lastError: lastError,
      );

  bool get hasPending => pendingCount > 0;
}

// ── Provider ───────────────────────────────────────────────────────────────
final syncProcessorProvider =
    StateNotifierProvider<SyncProcessor, SyncState>((ref) {
  final queue = ref.watch(syncQueueServiceProvider);
  final dio = ref.watch(dioProvider);
  return SyncProcessor(queue, dio, ref);
});

// ── Processor ─────────────────────────────────────────────────────────────
class SyncProcessor extends StateNotifier<SyncState> {
  final SyncQueueService _queue;
  final Dio _dio;
  final Ref _ref;
  StreamSubscription? _connectivitySub;

  SyncProcessor(this._queue, this._dio, this._ref) : super(const SyncState()) {
    _updateCount();
    _watchConnectivity();
  }

  void _updateCount() {
    state = state.copyWith(pendingCount: _queue.pendingCount);
  }

  void _watchConnectivity() {
    _connectivitySub = _ref.read(connectivityProvider.stream).listen((results) {
      final online = results.isNotEmpty && results.any((r) => r.name != 'none');
      if (online && state.hasPending && !state.isSyncing) {
        processQueue();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  /// Enqueue an operation without sending immediately (offline or caller's choice).
  Future<void> enqueue(PendingOperation op) async {
    await _queue.enqueue(op);
    _updateCount();
  }

  /// Attempt to flush all pending operations to the server.
  Future<void> processQueue() async {
    final pending = _queue.getPending();
    if (pending.isEmpty) return;

    state = state.copyWith(isSyncing: true, lastError: null);

    // Filter out operations that exceeded max retries
    final toSend = pending.where((op) => op.retryCount < _maxRetries).toList();
    final dead = pending.where((op) => op.retryCount >= _maxRetries).toList();

    // Remove dead-letter operations
    for (final op in dead) {
      await _queue.remove(op.clientId);
      if (kDebugMode) print('[Sync] Dead-letter removed: ${op.clientId}');
    }

    if (toSend.isEmpty) {
      state = state.copyWith(isSyncing: false, pendingCount: 0);
      return;
    }

    try {
      final response = await _dio.post(
        ApiConstants.syncBase,
        data: {
          'operations': toSend.map((op) => op.toServerJson()).toList(),
        },
      );

      final results = (response.data['results'] as List? ?? []);
      for (final result in results) {
        final clientId = result['clientId'] as String;
        final success = result['success'] as bool;
        if (success) {
          await _queue.remove(clientId);
        } else {
          await _queue.incrementRetry(clientId);
        }
      }

      state = state.copyWith(
        isSyncing: false,
        pendingCount: _queue.pendingCount,
        lastSyncAt: DateTime.now(),
      );
    } on DioException catch (e) {
      // Network error — increment retry count on all
      for (final op in toSend) {
        await _queue.incrementRetry(op.clientId);
      }
      state = state.copyWith(
        isSyncing: false,
        pendingCount: _queue.pendingCount,
        lastError: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
    }
  }

  /// Exponential backoff delay for retry index [attempt] (0-based).
  static Duration backoffDelay(int attempt) =>
      Duration(seconds: (2 << attempt).clamp(2, 30)); // 2s, 4s, 8s
}
