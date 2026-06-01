import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart'
    show dioProvider, friendlyErrorMessage;
import '../../data/datasources/favorite_datasource.dart';
import '../../data/models/favorite_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final favoriteDatasourceProvider = Provider<FavoriteDatasource>(
  (ref) => FavoriteDatasource(ref.watch(dioProvider)),
);

final favoriteViewModelProvider =
    StateNotifierProvider<FavoriteViewModel, FavoriteState>(
  (ref) => FavoriteViewModel(ref.watch(favoriteDatasourceProvider)),
);

// ---------------------------------------------------------------------------
// Estado
// ---------------------------------------------------------------------------

class FavoriteState {
  final List<FavoriteModel> items;
  final bool isLoading;
  final String? error;
  // IDs de restaurantes/pratos que estão favoritados (para lookup rápido)
  final Set<String> favoritedRestaurantIds;
  final Set<String> favoritedDishIds;

  const FavoriteState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.favoritedRestaurantIds = const {},
    this.favoritedDishIds = const {},
  });

  FavoriteState copyWith({
    List<FavoriteModel>? items,
    bool? isLoading,
    String? error,
    Set<String>? favoritedRestaurantIds,
    Set<String>? favoritedDishIds,
  }) =>
      FavoriteState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        favoritedRestaurantIds:
            favoritedRestaurantIds ?? this.favoritedRestaurantIds,
        favoritedDishIds: favoritedDishIds ?? this.favoritedDishIds,
      );
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class FavoriteViewModel extends StateNotifier<FavoriteState> {
  final FavoriteDatasource _ds;

  FavoriteViewModel(this._ds) : super(const FavoriteState());

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _ds.getAll();
      state = state.copyWith(
        items: items,
        isLoading: false,
        favoritedRestaurantIds:
            items.map((f) => f.restaurantId).whereType<String>().toSet(),
        favoritedDishIds:
            items.map((f) => f.dishId).whereType<String>().toSet(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: friendlyErrorMessage(e));
    }
  }

  bool isRestaurantFavorited(String restaurantId) =>
      state.favoritedRestaurantIds.contains(restaurantId);

  bool isDishFavorited(String dishId) =>
      state.favoritedDishIds.contains(dishId);

  /// Toggle otimista: atualiza a UI imediatamente e reverte em caso de erro.
  Future<void> toggleRestaurant(String restaurantId) async {
    final alreadyFav = isRestaurantFavorited(restaurantId);

    // Atualização otimista
    final newRestIds = Set<String>.from(state.favoritedRestaurantIds);
    List<FavoriteModel> newItems;
    if (alreadyFav) {
      newRestIds.remove(restaurantId);
      newItems =
          state.items.where((f) => f.restaurantId != restaurantId).toList();
    } else {
      newRestIds.add(restaurantId);
      newItems = state.items;
    }
    state = state.copyWith(
      favoritedRestaurantIds: newRestIds,
      items: newItems,
    );

    try {
      final result = await _ds.toggle(restaurantId: restaurantId);
      // Se adicionado, incluir o model retornado
      if (result['added'] == true && result['favorite'] != null) {
        final fav = result['favorite'] as FavoriteModel;
        state = state.copyWith(items: [...state.items, fav]);
      }
    } catch (e) {
      // Reverter em caso de erro
      final revertIds = Set<String>.from(state.favoritedRestaurantIds);
      if (alreadyFav) {
        revertIds.add(restaurantId);
      } else {
        revertIds.remove(restaurantId);
      }
      state = state.copyWith(
        favoritedRestaurantIds: revertIds,
        items: state.items,
        error: 'Erro ao atualizar favorito',
      );
    }
  }

  Future<void> toggleDish(String dishId) async {
    final alreadyFav = isDishFavorited(dishId);
    final newDishIds = Set<String>.from(state.favoritedDishIds);
    List<FavoriteModel> newItems;
    if (alreadyFav) {
      newDishIds.remove(dishId);
      newItems = state.items.where((f) => f.dishId != dishId).toList();
    } else {
      newDishIds.add(dishId);
      newItems = state.items;
    }
    state = state.copyWith(favoritedDishIds: newDishIds, items: newItems);
    try {
      final result = await _ds.toggle(dishId: dishId);
      if (result['added'] == true && result['favorite'] != null) {
        final fav = result['favorite'] as FavoriteModel;
        state = state.copyWith(items: [...state.items, fav]);
      }
    } catch (_) {
      final revertIds = Set<String>.from(state.favoritedDishIds);
      if (alreadyFav) {
        revertIds.add(dishId);
      } else {
        revertIds.remove(dishId);
      }
      state = state.copyWith(
        favoritedDishIds: revertIds,
        error: 'Erro ao atualizar favorito',
      );
    }
  }
}
