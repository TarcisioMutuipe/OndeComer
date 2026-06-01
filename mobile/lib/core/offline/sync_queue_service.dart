import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pending_operation.dart';

const _boxName = 'sync_queue';

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  return SyncQueueService();
});

/// Manages a local Hive box that stores pending offline operations.
class SyncQueueService {
  Box<PendingOperation>? _box;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PendingOperationAdapter());
    }
    _box = await Hive.openBox<PendingOperation>(_boxName);
  }

  Box<PendingOperation> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('SyncQueueService not initialized. Call init() first.');
    }
    return _box!;
  }

  /// Enqueues an operation. Returns the clientId.
  Future<String> enqueue(PendingOperation op) async {
    await box.put(op.clientId, op);
    return op.clientId;
  }

  /// All pending operations sorted by timestamp (oldest first).
  List<PendingOperation> getPending() {
    return box.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  int get pendingCount => box.length;

  Future<void> remove(String clientId) async {
    await box.delete(clientId);
  }

  Future<void> incrementRetry(String clientId) async {
    final op = box.get(clientId);
    if (op != null) {
      op.retryCount++;
      await op.save();
    }
  }

  Future<void> clearAll() async {
    await box.clear();
  }
}
