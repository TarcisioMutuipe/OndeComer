import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/favorite_model.dart';

class FavoriteDatasource {
  final Dio _dio;
  FavoriteDatasource(this._dio);

  Future<List<FavoriteModel>> getAll() async {
    final response = await _dio.get(ApiConstants.favoritesBase);
    return (response.data as List)
        .map((e) => FavoriteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> check({String? restaurantId, String? dishId}) async {
    final params = <String, dynamic>{
      if (restaurantId != null) 'restaurantId': restaurantId,
      if (dishId != null) 'dishId': dishId,
    };
    final response = await _dio.get(
      ApiConstants.favoritesCheck,
      queryParameters: params,
    );
    return response.data['isFavorited'] as bool;
  }

  /// Retorna `{added: bool, favorite: FavoriteModel?}`
  Future<Map<String, dynamic>> toggle(
      {String? restaurantId, String? dishId}) async {
    final response = await _dio.post(
      ApiConstants.favoritesToggle,
      data: {
        if (restaurantId != null) 'restaurantId': restaurantId,
        if (dishId != null) 'dishId': dishId,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return {
      'added': data['added'] as bool,
      'favorite': data['favorite'] != null
          ? FavoriteModel.fromJson(data['favorite'] as Map<String, dynamic>)
          : null,
    };
  }
}
