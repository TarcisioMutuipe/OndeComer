import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/restaurant_model.dart';

final restaurantListDatasourceProvider =
    Provider((ref) => RestaurantListDatasource(ref.watch(dioProvider)));

class RestaurantListDatasource {
  final Dio _dio;
  RestaurantListDatasource(this._dio);

  Future<Map<String, dynamic>> getRestaurants({
    String? search,
    String? category,
    String city = 'Salvador',
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      ApiConstants.restaurantsBase,
      queryParameters: {
        'city': city,
        'page': page,
        'pageSize': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<RestaurantModel> getById(String id) async {
    final response = await _dio.get(ApiConstants.restaurantById(id));
    return RestaurantModel.fromJson(response.data as Map<String, dynamic>);
  }
}
