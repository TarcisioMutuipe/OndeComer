import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onde_comer_em_salvador/features/admin/data/datasources/admin_restaurant_datasource.dart';
import 'package:onde_comer_em_salvador/core/network/dio_client.dart';

final adminRestaurantDataSourceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AdminRestaurantDataSource(dio: dio);
});

/// StateNotifier para gerenciar restaurantes do admin
class AdminRestaurantNotifier
  extends StateNotifier<AsyncValue<List<AdminRestaurantEntry>>> {
  final AdminRestaurantDataSource dataSource;
  final Ref ref;

  AdminRestaurantNotifier({
    required this.dataSource,
    required this.ref,
  }) : super(const AsyncValue.loading());

  Future<void> loadRestaurants({String? search, String? category}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => dataSource.getRestaurants(
          search: search,
          category: category,
        ));
  }

  Future<void> updateRestaurant(String id, Map<String, dynamic> data) async {
    try {
      final updated = await dataSource.updateRestaurant(id, data);
      state = AsyncValue.data([
        ...?state.whenData((restaurants) => restaurants).value,
      ].map((entry) => entry.restaurant.id == id
          ? entry.copyWith(restaurant: updated)
          : entry).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> deleteRestaurant(String id) async {
    try {
      await dataSource.deleteRestaurant(id);
      state = AsyncValue.data([
        ...?state.whenData((restaurants) => restaurants).value,
      ].where((entry) => entry.restaurant.id != id).toList());
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> addYouTubeUrl(String restaurantId, String url) async {
    try {
      final updated = await dataSource.addYouTubeUrl(restaurantId, url);
      state = AsyncValue.data([
        ...?state.whenData((restaurants) => restaurants).value,
      ].map((entry) => entry.restaurant.id == restaurantId
          ? entry.copyWith(restaurant: updated)
          : entry).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminRestaurantProvider = StateNotifierProvider<AdminRestaurantNotifier,
  AsyncValue<List<AdminRestaurantEntry>>>((ref) {
  final dataSource = ref.watch(adminRestaurantDataSourceProvider);
  return AdminRestaurantNotifier(dataSource: dataSource, ref: ref);
});
