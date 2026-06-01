import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dish_model.dart';
import '../../data/repositories/restaurant_repository_impl.dart';
import 'restaurant_viewmodel.dart';

final dishViewModelProvider =
    StateNotifierProvider.family<DishViewModel, DishState, String>(
        (ref, restaurantId) {
  return DishViewModel(ref.watch(restaurantRepositoryProvider), restaurantId);
});

class DishState {
  final List<DishModel> dishes;
  final bool isLoading;
  final String? error;

  const DishState({this.dishes = const [], this.isLoading = false, this.error});

  DishState copyWith(
          {List<DishModel>? dishes, bool? isLoading, String? error}) =>
      DishState(
        dishes: dishes ?? this.dishes,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class DishViewModel extends StateNotifier<DishState> {
  final RestaurantRepositoryImpl _repo;
  final String _restaurantId;

  DishViewModel(this._repo, this._restaurantId) : super(const DishState());

  Future<void> loadDishes({bool onlyAvailable = false}) async {
    print(
        '[DishVM] loadDishes called for restaurant=$_restaurantId onlyAvailable=$onlyAvailable');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final List<DishModel> dishes = await _repo.getDishes(_restaurantId,
          onlyAvailable: onlyAvailable, forceRefresh: true);
      print('[DishVM] loaded ${dishes.length} dishes');
      state = state.copyWith(dishes: dishes, isLoading: false);
    } catch (e, st) {
      print('[DishVM] ERROR: $e');
      print('[DishVM] StackTrace: $st');
      state = state.copyWith(isLoading: false, error: _mapError(e));
    }
  }

  Future<bool> createDish(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dish = await _repo.createDish(_restaurantId, data);
      state = state.copyWith(
          dishes: [...state.dishes, dish as DishModel], isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _mapError(e));
      return false;
    }
  }

  Future<bool> updateDish(String dishId, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repo.updateDish(dishId, data) as DishModel;
      final dishes =
          state.dishes.map((d) => d.id == dishId ? updated : d).toList();
      state = state.copyWith(dishes: dishes, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _mapError(e));
      return false;
    }
  }

  Future<bool> deleteDish(String dishId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.deleteDish(dishId);
      final dishes = state.dishes.where((d) => d.id != dishId).toList();
      state = state.copyWith(dishes: dishes, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _mapError(e));
      return false;
    }
  }

  String _mapError(Object e) {
    if (e is DioException) {
      // Tentar extrair mensagem do corpo da resposta
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final msg =
            data['error'] ?? data['message'] ?? data['title'] ?? data['detail'];
        if (msg != null) return msg.toString();
      }
      // Mensagens padrão por status
      final status = e.response?.statusCode;
      if (status == 409)
        return 'Já existe um prato com esse nome neste restaurante.';
      if (status == 403) return 'Você não tem permissão para esta ação.';
      if (status == 404) return 'Recurso não encontrado.';
      if (status == 400) return 'Dados inválidos. Verifique os campos.';
    }
    return 'Algo deu errado. Tente novamente.';
  }
}
