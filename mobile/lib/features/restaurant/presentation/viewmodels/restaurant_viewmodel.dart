import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/restaurant_remote_datasource.dart';
import '../../data/models/restaurant_model.dart';
import '../../data/repositories/restaurant_repository_impl.dart';
import '../../../../core/network/dio_client.dart'
    show dioProvider, friendlyErrorMessage;

// Providers
final restaurantRemoteDatasourceProvider = Provider((ref) {
  return RestaurantRemoteDatasource(ref.watch(dioProvider));
});

final restaurantRepositoryProvider = Provider((ref) {
  return RestaurantRepositoryImpl(
      ref.watch(restaurantRemoteDatasourceProvider));
});

final restaurantViewModelProvider =
    StateNotifierProvider<RestaurantViewModel, RestaurantState>((ref) {
  return RestaurantViewModel(ref.watch(restaurantRepositoryProvider));
});

class RestaurantState {
  final RestaurantModel? restaurant;
  final bool isLoading;
  final String? error;

  const RestaurantState({this.restaurant, this.isLoading = false, this.error});

  RestaurantState copyWith({
    RestaurantModel? restaurant,
    bool? isLoading,
    String? error,
  }) =>
      RestaurantState(
        restaurant: restaurant ?? this.restaurant,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class RestaurantViewModel extends StateNotifier<RestaurantState> {
  final RestaurantRepositoryImpl _repo;

  RestaurantViewModel(this._repo) : super(const RestaurantState());

  Future<void> loadMyRestaurant() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final r = await _repo.getMyRestaurant();
      state = state.copyWith(restaurant: r, isLoading: false);
    } on DioException catch (e) {
      // 404 = usuário ainda não tem restaurante — não é erro
      if (e.response?.statusCode == 404) {
        state = state.copyWith(isLoading: false, error: null);
      } else {
        state =
            state.copyWith(isLoading: false, error: friendlyErrorMessage(e));
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: friendlyErrorMessage(e));
    }
  }

  Future<bool> createRestaurant(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final r = await _repo.createRestaurant(data);
      state = state.copyWith(restaurant: r, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: friendlyErrorMessage(e));
      return false;
    }
  }

  Future<bool> updateRestaurant(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final r = await _repo.updateRestaurant(id, data);
      state = state.copyWith(restaurant: r, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: friendlyErrorMessage(e));
      return false;
    }
  }
}
