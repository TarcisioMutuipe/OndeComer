import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/favorites/presentation/viewmodels/favorite_viewmodel.dart';

/// Botão de favorito reutilizável.
/// Use [restaurantId] para favoritar restaurante ou [dishId] para prato.
class FavoriteButton extends ConsumerWidget {
  final String? restaurantId;
  final String? dishId;
  final double size;
  final Color? activeColor;

  const FavoriteButton({
    super.key,
    this.restaurantId,
    this.dishId,
    this.size = 24,
    this.activeColor,
  }) : assert(
          restaurantId != null || dishId != null,
          'Informe restaurantId ou dishId',
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoriteViewModelProvider);
    final vm = ref.read(favoriteViewModelProvider.notifier);

    final isFav = restaurantId != null
        ? state.favoritedRestaurantIds.contains(restaurantId)
        : state.favoritedDishIds.contains(dishId);

    return IconButton(
      icon: Icon(
        isFav ? Icons.favorite : Icons.favorite_border,
        size: size,
        color: isFav ? (activeColor ?? Colors.red) : null,
      ),
      tooltip: isFav ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
      onPressed: () {
        if (restaurantId != null) {
          vm.toggleRestaurant(restaurantId!);
        } else {
          vm.toggleDish(dishId!);
        }
      },
    );
  }
}
