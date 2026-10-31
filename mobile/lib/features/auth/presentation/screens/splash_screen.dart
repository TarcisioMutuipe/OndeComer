import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    // Redireciona quando estado já está resolvido (inclusive antes do listener registrar)
    if (!authState.isLoading && authState.status != AuthStatus.unknown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (authState.status == AuthStatus.authenticated) {
          context.go(AppRoutes.home);
        } else {
          context.go(AppRoutes.login);
        }
      });
    }

    ref.listen<AuthState>(authViewModelProvider, (prev, next) {
      if (next.isLoading) return;
      if (next.status == AuthStatus.authenticated) {
        context.go(AppRoutes.home);
      } else if (next.status == AuthStatus.unauthenticated) {
        context.go(AppRoutes.login);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/logo.svg',
              width: 300,
              height: 110,
              placeholderBuilder: (_) => const Icon(
                Icons.restaurant_menu,
                size: 64,
                color: AppTheme.primaryYellowDark,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: AppTheme.primaryYellowDark),
          ],
        ),
      ),
    );
  }
}
