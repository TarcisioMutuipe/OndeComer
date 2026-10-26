import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/offline/sync_queue_service.dart';
import 'app/app.dart';

Future<void> _initializeFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {
    // Firebase is optional until the platform config files are present.
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await _initializeFirebase();

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
