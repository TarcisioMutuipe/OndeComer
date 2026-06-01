import 'package:hive/hive.dart';
import '../../domain/repositories/restaurant_repository.dart';
import '../datasources/restaurant_remote_datasource.dart';
import '../models/dish_model.dart';
import '../models/restaurant_model.dart';

class RestaurantRepositoryImpl implements RestaurantRepository {
  final RestaurantRemoteDatasource _remote;
  static const _menuBoxName = 'menu_cache';
  static const _menuTtlKey = 'menu_ttl_';

  RestaurantRepositoryImpl(this._remote);

  @override
  Future<RestaurantModel> getMyRestaurant() => _remote.getMyRestaurant();

  @override
  Future<RestaurantModel> getRestaurantById(String id) =>
      _remote.getRestaurantById(id);

  @override
  Future<List<RestaurantModel>> getAllRestaurants() =>
      _remote.getAllRestaurants();

  @override
  Future<RestaurantModel> createRestaurant(Map<String, dynamic> data) =>
      _remote.createRestaurant(data);

  @override
  Future<RestaurantModel> updateRestaurant(
          String id, Map<String, dynamic> data) =>
      _remote.updateRestaurant(id, data);

  @override
  Future<List<DishModel>> getDishes(String restaurantId,
      {bool onlyAvailable = false, bool forceRefresh = false}) async {
    // Se forceRefresh, buscar direto da API sem cache
    if (forceRefresh) {
      return _remote.getDishes(restaurantId, onlyAvailable: onlyAvailable);
    }

    // Cache key inclui onlyAvailable para evitar mistura de resultados
    final cacheKey = '${restaurantId}_$onlyAvailable';
    final box = await Hive.openBox(_menuBoxName);
    final ttlKey = '$_menuTtlKey$cacheKey';
    final cachedAt = box.get(ttlKey) as int?;
    final now = DateTime.now().millisecondsSinceEpoch;
    const ttl = 24 * 60 * 60 * 1000; // 24h in ms

    if (cachedAt != null && (now - cachedAt) < ttl) {
      final cached = box.get(cacheKey) as List?;
      if (cached != null) {
        return cached
            .map((e) => DishModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    }

    final dishes =
        await _remote.getDishes(restaurantId, onlyAvailable: onlyAvailable);
    await box.put(cacheKey, dishes.map((d) => d.toJson()).toList());
    await box.put(ttlKey, now);
    return dishes;
  }

  @override
  Future<void> clearMenuCache(String restaurantId) async {
    final box = await Hive.openBox(_menuBoxName);
    // Limpar ambas variantes (onlyAvailable true/false)
    for (final variant in ['${restaurantId}_true', '${restaurantId}_false']) {
      await box.delete(variant);
      await box.delete('$_menuTtlKey$variant');
    }
    // Compatibilidade com chave antiga
    await box.delete(restaurantId);
    await box.delete('$_menuTtlKey$restaurantId');
  }

  @override
  Future<DishModel> createDish(
      String restaurantId, Map<String, dynamic> data) async {
    final dish = await _remote.createDish(restaurantId, data);
    await clearMenuCache(restaurantId);
    return dish;
  }

  @override
  Future<DishModel> updateDish(String dishId, Map<String, dynamic> data) async {
    final dish = await _remote.updateDish(dishId, data);
    await clearMenuCache(dish.restaurantId);
    return dish;
  }

  @override
  Future<void> deleteDish(String dishId) async {
    // Fetch dish first to know restaurantId for cache invalidation
    await _remote.deleteDish(dishId);
  }
}
