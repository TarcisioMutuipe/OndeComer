import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/notifications/push_notification_service.dart';
import '../shared/widgets/offline_banner.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class OndeComerApp extends ConsumerStatefulWidget {
  const OndeComerApp({super.key});

  @override
  ConsumerState<OndeComerApp> createState() => _OndeComerAppState();
}

class _OndeComerAppState extends ConsumerState<OndeComerApp> {
  bool _pushConfigured = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final pushService = ref.read(pushNotificationServiceProvider);

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.user != null) {
        pushService.syncCurrentUser(next.user);
      } else if (previous?.user != null && next.user == null) {
        pushService.clearCurrentUser();
      }
    });

    if (!_pushConfigured) {
      _pushConfigured = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        pushService.initialize(
          messengerKey: rootScaffoldMessengerKey,
          router: router,
        );
        final authState = ref.read(authViewModelProvider);
        if (authState.user != null) {
          pushService.syncCurrentUser(authState.user);
        }
      });
    }

    return MaterialApp.router(
      title: 'Onde Comer Em Salvador',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: router,
      builder: (context, child) => OfflineBannerWrapper(child: child!),
    );
  }
}
