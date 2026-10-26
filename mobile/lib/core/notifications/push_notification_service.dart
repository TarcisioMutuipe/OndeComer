import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/models/user_model.dart';
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../router/app_router.dart';

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref.watch(notificationDatasourceProvider));
});

class PushNotificationService {
  final NotificationRemoteDatasource _datasource;

  PushNotificationService(this._datasource);

  GlobalKey<ScaffoldMessengerState>? _messengerKey;
  GoRouter? _router;
  bool _initialized = false;
  bool _firebaseReady = false;
  String? _registeredToken;
  String? _currentUserId;
  StreamSubscription<String>? _tokenRefreshSub;

  Future<void> initialize({
    required GlobalKey<ScaffoldMessengerState> messengerKey,
    required GoRouter router,
  }) async {
    _messengerKey = messengerKey;
    _router = router;

    if (_initialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _firebaseReady = true;
    } catch (_) {
      _firebaseReady = false;
      _initialized = true;
      return;
    }

    try {
      await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleOpenedMessage(initialMessage);
      }
    } catch (_) {
      _firebaseReady = false;
    }

    _initialized = true;
  }

  Future<void> syncCurrentUser(UserModel? user) async {
    if (!_firebaseReady) return;

    if (user == null) {
      await clearCurrentUser();
      return;
    }

    final token = await _resolveToken();
    if (token == null || token.isEmpty) return;

    if (_currentUserId == user.id && _registeredToken == token) {
      _listenTokenRefresh();
      return;
    }

    await _datasource.registerDevice(
      platform: _platformName(),
      fcmToken: token,
    );
    _registeredToken = token;
    _currentUserId = user.id;
    _listenTokenRefresh();
  }

  Future<void> clearCurrentUser() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    if (_registeredToken != null) {
      try {
        await _datasource.unregisterDevice(fcmToken: _registeredToken);
      } catch (_) {
        // Ignore cleanup failures.
      }
    }

    _registeredToken = null;
    _currentUserId = null;
  }

  Future<String?> _resolveToken() async {
    try {
      if (kIsWeb) {
        return await FirebaseMessaging.instance.getToken();
      }
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  void _listenTokenRefresh() {
    if (_tokenRefreshSub != null) return;
    _tokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (_currentUserId == null) return;
      try {
        await _datasource.registerDevice(
          platform: _platformName(),
          fcmToken: newToken,
        );
        _registeredToken = newToken;
      } catch (_) {
        // Ignore refresh registration failures.
      }
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'Nova notificação';
    final body = message.notification?.body ?? '';
    _messengerKey?.currentState?.showSnackBar(
      SnackBar(content: Text(body.isNotEmpty ? '$title: $body' : title)),
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final deepLink = message.data['deepLink']?.toString();
    if (deepLink != null && deepLink.isNotEmpty && _router != null) {
      _router!.go(deepLink);
      return;
    }

    final promotionId = message.data['promotionId']?.toString();
    if (promotionId != null && promotionId.isNotEmpty && _router != null) {
      _router!.go(AppRoutes.feed);
    }
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'web';
    }
  }
}
