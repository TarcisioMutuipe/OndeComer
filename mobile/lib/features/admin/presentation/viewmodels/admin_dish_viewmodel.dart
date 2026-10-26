import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onde_comer_em_salvador/features/admin/data/datasources/admin_dish_datasource.dart';
import 'package:onde_comer_em_salvador/features/restaurant/data/models/dish_model.dart';
import 'package:onde_comer_em_salvador/core/network/dio_client.dart';

final adminDishDataSourceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AdminDishDataSource(dio: dio);
});

/// StateNotifier para gerenciar pratos do admin
class AdminDishNotifier extends StateNotifier<AsyncValue<List<DishModel>>> {
  final AdminDishDataSource dataSource;
  final Ref ref;
  String? currentRestaurantId;

  AdminDishNotifier({
    required this.dataSource,
    required this.ref,
  }) : super(const AsyncValue.loading());

  Future<void> loadDishes(String restaurantId, {String? search}) async {
    currentRestaurantId = restaurantId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => dataSource.getDishes(
          restaurantId: restaurantId,
          search: search,
        ));
  }

  Future<void> createDish(Map<String, dynamic> data) async {
    try {
      final newDish = await dataSource.createDish(data);
      state = AsyncValue.data([
        ...?state.whenData((dishes) => dishes).value,
        newDish,
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateDish(String id, Map<String, dynamic> data) async {
    try {
      final updated = await dataSource.updateDish(id, data);
      state = AsyncValue.data([
        ...?state.whenData((dishes) => dishes).value,
      ].map((d) => d.id == id ? updated : d).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteDish(String id) async {
    try {
      await dataSource.deleteDish(id);
      state = AsyncValue.data([
        ...?state.whenData((dishes) => dishes).value,
      ].where((d) => d.id != id).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleAvailability(String id) async {
    try {
      final updated = await dataSource.toggleDishAvailability(id);
      state = AsyncValue.data([
        ...?state.whenData((dishes) => dishes).value,
      ].map((d) => d.id == id ? updated : d).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminDishProvider =
    StateNotifierProvider<AdminDishNotifier, AsyncValue<List<DishModel>>>(
        (ref) {
  final dataSource = ref.watch(adminDishDataSourceProvider);
  return AdminDishNotifier(dataSource: dataSource, ref: ref);
});
