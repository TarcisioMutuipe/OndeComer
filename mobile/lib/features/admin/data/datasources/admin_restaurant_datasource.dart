import 'package:dio/dio.dart';
import 'package:onde_comer_em_salvador/core/constants/api_constants.dart';
import 'package:onde_comer_em_salvador/features/restaurant/data/models/restaurant_model.dart';

class AdminRestaurantEntry {
  final RestaurantModel restaurant;
  final bool hasDuplicateName;
  final bool hasAdminAndUserDuplicate;

  const AdminRestaurantEntry({
    required this.restaurant,
    this.hasDuplicateName = false,
    this.hasAdminAndUserDuplicate = false,
  });

  AdminRestaurantEntry copyWith({RestaurantModel? restaurant}) =>
      AdminRestaurantEntry(
        restaurant: restaurant ?? this.restaurant,
        hasDuplicateName: hasDuplicateName,
        hasAdminAndUserDuplicate: hasAdminAndUserDuplicate,
      );
}

class AdminRestaurantDataSource {
  final Dio dio;

  AdminRestaurantDataSource({required this.dio});

  /// Obter lista de todos os restaurantes para admin
  Future<List<AdminRestaurantEntry>> getRestaurants({
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
        final raw = response.data;
        final List<dynamic> data = raw is List
            ? raw
            : (raw is Map && raw['data'] is List
                ? raw['data']
                : (raw is Map && raw['items'] is List ? raw['items'] : []));
        return data.map((json) {
          final map = json as Map<String, dynamic>;
          return AdminRestaurantEntry(
            restaurant: _parseRestaurantModel(map),
            hasDuplicateName: map['hasDuplicateName'] as bool? ?? false,
            hasAdminAndUserDuplicate:
                map['hasAdminAndUserDuplicate'] as bool? ?? false,
          );
        }).toList();
      }
      throw Exception('Erro ao carregar restaurantes');
    } catch (e) {
      rethrow;
    }
  }

  Future<RestaurantModel> createRestaurant(Map<String, dynamic> data) async {
    final response = await dio.post(
      '${ApiConstants.adminBase}/restaurants',
      data: data,
    );
    final raw = response.data;
    final map = raw is Map && raw['data'] is Map
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return _parseRestaurantModel(map);
  }

  static RestaurantModel _parseRestaurantModel(Map<String, dynamic> map) {
    return RestaurantModel(
      id: map['id']?.toString() ?? '',
      ownerUserId: map['ownerUserId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
      address: map['address']?.toString() ?? '',
      city: map['city']?.toString() ?? 'Salvador',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      category: map['category']?.toString() ?? '',
      logoUrl: map['logoUrl']?.toString(),
      coverUrl: map['coverUrl']?.toString(),
      instagramUrl: map['instagramUrl']?.toString(),
      youTubeVideoUrl: map['youTubeVideoUrl']?.toString(),
      isActive: map['isActive'] as bool? ?? true,
      openingHours: map['openingHours']?.toString() ?? '',
      dishCount: (map['dishCount'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Obter detalhes de um restaurante
  Future<RestaurantModel> getRestaurantDetails(String restaurantId) async {
    try {
      final response = await dio.get(
        '${ApiConstants.adminBase}/restaurants/$restaurantId',
      );

      if (response.statusCode == 200) {
        final raw = response.data;
        final map = (raw is Map && raw.containsKey('data') && raw['data'] is Map)
            ? raw['data'] as Map<String, dynamic>
            : raw as Map<String, dynamic>;
        return _parseRestaurantModel(map);
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
        final raw = response.data;
        final map = (raw is Map && raw.containsKey('data') && raw['data'] is Map)
            ? raw['data'] as Map<String, dynamic>
            : raw as Map<String, dynamic>;
        return _parseRestaurantModel(map);
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
        final raw = response.data;
        final map = (raw is Map && raw.containsKey('data') && raw['data'] is Map)
            ? raw['data'] as Map<String, dynamic>
            : raw as Map<String, dynamic>;
        return _parseRestaurantModel(map);
      }
      throw Exception('Erro ao adicionar URL do YouTube');
    } catch (e) {
      rethrow;
    }
  }
}
