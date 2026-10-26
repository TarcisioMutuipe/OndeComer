import 'package:dio/dio.dart';
import 'package:onde_comer_em_salvador/core/constants/api_constants.dart';
import 'package:onde_comer_em_salvador/features/restaurant/data/models/restaurant_model.dart';

class AdminRestaurantDataSource {
  final Dio dio;

  AdminRestaurantDataSource({required this.dio});

  /// Obter lista de todos os restaurantes para admin
  Future<List<RestaurantModel>> getRestaurants({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? category,
  }) async {
    try {
      final response = await dio.get(
        '${ApiConstants.adminBase}/restaurants',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (search != null) 'search': search,
          if (category != null) 'category': category,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data
            .map((json) =>
                RestaurantModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Erro ao carregar restaurantes');
    } catch (e) {
      rethrow;
    }
  }

  /// Obter detalhes de um restaurante
  Future<RestaurantModel> getRestaurantDetails(String restaurantId) async {
    try {
      final response = await dio.get(
        '${ApiConstants.adminBase}/restaurants/$restaurantId',
      );

      if (response.statusCode == 200) {
        return RestaurantModel.fromJson(response.data['data']);
      }
      throw Exception('Erro ao carregar restaurante');
    } catch (e) {
      rethrow;
    }
  }

  /// Atualizar restaurante
  Future<RestaurantModel> updateRestaurant(
    String restaurantId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.put(
        '${ApiConstants.adminBase}/restaurants/$restaurantId',
        data: data,
      );

      if (response.statusCode == 200) {
        return RestaurantModel.fromJson(response.data['data']);
      }
      throw Exception('Erro ao atualizar restaurante');
    } catch (e) {
      rethrow;
    }
  }

  /// Deletar restaurante
  Future<void> deleteRestaurant(String restaurantId) async {
    try {
      final response = await dio.delete(
        '${ApiConstants.adminBase}/restaurants/$restaurantId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erro ao deletar restaurante');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Adicionar YouTube URL ao restaurante
  Future<RestaurantModel> addYouTubeUrl(
    String restaurantId,
    String youtubeUrl,
  ) async {
    try {
      final response = await dio.put(
        '${ApiConstants.adminBase}/restaurants/$restaurantId',
        data: {
          'youtubeVideoUrl': youtubeUrl,
        },
      );

      if (response.statusCode == 200) {
        return RestaurantModel.fromJson(response.data['data']);
      }
      throw Exception('Erro ao adicionar URL do YouTube');
    } catch (e) {
      rethrow;
    }
  }
}
