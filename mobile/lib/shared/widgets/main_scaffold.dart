import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'offline_banner.dart';
import 'sync_pending_badge.dart';

final _navIndexProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  static const _consumerTabs = [
    _NavTab(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Início',
        route: '/home'),
    _NavTab(
        icon: Icons.search_outlined,
        activeIcon: Icons.search,
        label: 'Busca',
        route: '/search'),
    _NavTab(
        icon: Icons.local_offer_outlined,
        activeIcon: Icons.local_offer,
        label: 'Ofertas & Tickets',
        route: '/feed'),
    _NavTab(
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events,
      label: 'Rankings',
      route: '/rankings'),
    _NavTab(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Perfil',
        route: '/profile'),
  ];

  static const _restaurantTabs = [
    _NavTab(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Painel',
        route: '/restaurant/panel'),
    _NavTab(
        icon: Icons.restaurant_menu_outlined,
        activeIcon: Icons.restaurant_menu,
        label: 'Cardápio',
        route: '/restaurant/dashboard'),
    _NavTab(
        icon: Icons.local_offer_outlined,
        activeIcon: Icons.local_offer,
        label: 'Promoções',
        route: '/feed'),
    _NavTab(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Perfil',
        route: '/profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;
    final isRestaurant = user?.profileType == 'Restaurant';
    final tabs = isRestaurant ? _restaurantTabs : _consumerTabs;

    // Sync nav index with current route
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final routeIndex = tabs.indexWhere((t) => t.route == currentRoute);
    if (routeIndex >= 0) {
      final storedIndex = ref.read(_navIndexProvider);
      if (storedIndex != routeIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(_navIndexProvider.notifier).state = routeIndex;
        });
      }
    }
    final index = ref.watch(_navIndexProvider);

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.white,
          border: Border(top: BorderSide(color: AppTheme.divider, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(tabs.length, (i) {
                final tab = tabs[i];
                final selected = i == index;
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      ref.read(_navIndexProvider.notifier).state = i;
                      context.go(tab.route);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? tab.activeIcon : tab.icon,
                          color: selected
                              ? AppTheme.primaryYellow
                              : AppTheme.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: selected
                                ? AppTheme.primaryYellow
                                : AppTheme.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  const _NavTab(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.route});
}
