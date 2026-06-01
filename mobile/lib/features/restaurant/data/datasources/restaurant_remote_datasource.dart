import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/dish_model.dart';
import '../models/restaurant_model.dart';

class RestaurantRemoteDatasource {
  final Dio _dio;

  RestaurantRemoteDatasource(this._dio);

  Future<RestaurantModel> getMyRestaurant() async {
    final response = await _dio.get(ApiConstants.restaurantMe);
    return RestaurantModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RestaurantModel> getRestaurantById(String id) async {
    final response = await _dio.get(ApiConstants.restaurantById(id));
    return RestaurantModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<RestaurantModel>> getAllRestaurants() async {
    final response = await _dio.get(ApiConstants.restaurantsBase);
    return (response.data as List)
        .map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RestaurantModel> createRestaurant(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.restaurantsBase, data: data);
    return RestaurantModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RestaurantModel> updateRestaurant(
      String id, Map<String, dynamic> data) async {
    final response =
        await _dio.put(ApiConstants.restaurantById(id), data: data);
    return RestaurantModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<DishModel>> getDishes(String restaurantId,
      {bool onlyAvailable = false}) async {
    final response = await _dio.get(ApiConstants.restaurantDishes(restaurantId,
        onlyAvailable: onlyAvailable));
    return (response.data as List)
        .map((e) => DishModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DishModel> createDish(
      String restaurantId, Map<String, dynamic> data) async {
    final response =
        await _dio.post(ApiConstants.createDish(restaurantId), data: data);
    return DishModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DishModel> updateDish(String dishId, Map<String, dynamic> data) async {
    final response = await _dio.put(ApiConstants.dishById(dishId), data: data);
    return DishModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteDish(String dishId) async {
    await _dio.delete(ApiConstants.dishById(dishId));
  }
}
