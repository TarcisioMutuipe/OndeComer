import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/offline/sync_queue_service.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Initialize offline queue
  final syncQueue = SyncQueueService();
  await syncQueue.init();

  runApp(ProviderScope(
    overrides: [
      syncQueueServiceProvider.overrideWithValue(syncQueue),
    ],
    child: const OndeComerApp(),
  ));
}
