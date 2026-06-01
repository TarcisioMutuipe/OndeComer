import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../restaurant/presentation/screens/restaurant_list_screen.dart';
import '../../../../shared/widgets/main_scaffold.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;
    final isRestaurant = user?.profileType == 'Restaurant';

    if (isRestaurant) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/restaurant/panel');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MainScaffold(child: const RestaurantListScreen());
  }
}
