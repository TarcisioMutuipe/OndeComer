import '../../data/models/dish_model.dart';
import '../../data/models/restaurant_model.dart';

abstract class RestaurantRepository {
  Future<RestaurantModel> getMyRestaurant();
  Future<RestaurantModel> getRestaurantById(String id);
  Future<List<RestaurantModel>> getAllRestaurants();
  Future<RestaurantModel> createRestaurant(Map<String, dynamic> data);
  Future<RestaurantModel> updateRestaurant(
      String id, Map<String, dynamic> data);
  Future<List<DishModel>> getDishes(String restaurantId,
      {bool onlyAvailable = false, bool forceRefresh = false});
  Future<void> clearMenuCache(String restaurantId);
  Future<DishModel> createDish(String restaurantId, Map<String, dynamic> data);
  Future<DishModel> updateDish(String dishId, Map<String, dynamic> data);
  Future<void> deleteDish(String dishId);
}
