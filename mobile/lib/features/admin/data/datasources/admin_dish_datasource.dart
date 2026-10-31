import 'package:dio/dio.dart';
import 'package:onde_comer_em_salvador/core/constants/api_constants.dart';
import 'package:onde_comer_em_salvador/features/restaurant/data/models/dish_model.dart';

class AdminDishDataSource {
  final Dio dio;

  AdminDishDataSource({required this.dio});

  /// Obter todos os pratos de um restaurante
  Future<List<DishModel>> getDishes({
    required String restaurantId,
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.restaurantDishes(restaurantId, onlyAvailable: false),
      );

      if (response.statusCode == 200) {
        final raw = response.data;
        final List<dynamic> data = raw is List
            ? raw
            : (raw is Map && raw['data'] is List ? raw['data'] : []);
        final dishes = data
            .map((json) => DishModel.fromJson(json as Map<String, dynamic>))
            .toList();
        final filtered = search == null || search.isEmpty
            ? dishes
            : dishes
                .where((dish) =>
                    dish.name.toLowerCase().contains(search.toLowerCase()))
                .toList();
        return filtered.skip((page - 1) * pageSize).take(pageSize).toList();
      }
      throw Exception('Erro ao carregar pratos');
    } catch (e) {
      rethrow;
    }
  }

  /// Obter detalhes de um prato
  Future<DishModel> getDishDetails(String dishId) async {
    try {
      final response = await dio.get(
        ApiConstants.dishById(dishId),
      );

      if (response.statusCode == 200) {
        final raw = response.data;
        final map = raw is Map && raw['data'] is Map
            ? raw['data'] as Map<String, dynamic>
            : raw as Map<String, dynamic>;
        return DishModel.fromJson(map);
      }
      throw Exception('Erro ao carregar prato');
    } catch (e) {
      rethrow;
    }
  }

  /// Criar novo prato
  Future<DishModel> createDish(Map<String, dynamic> data) async {
    try {
      final restaurantId = data['restaurantId']?.toString();
      if (restaurantId == null || restaurantId.isEmpty) {
        throw ArgumentError('restaurantId é obrigatório para criar um prato.');
      }
      final request = Map<String, dynamic>.from(data)
        ..remove('restaurantId')
        ..remove('isAvailable');
      final response = await dio.post(
        ApiConstants.createDish(restaurantId),
        data: request,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = response.data;
        final map = raw is Map && raw['data'] is Map
            ? raw['data'] as Map<String, dynamic>
            : raw as Map<String, dynamic>;
        return DishModel.fromJson(map);
      }
      throw Exception('Erro ao criar prato');
    } catch (e) {
      rethrow;
    }
  }

  /// Atualizar prato
  Future<DishModel> updateDish(
    String dishId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.put(
        '${ApiConstants.adminBase}/dishes/$dishId',
        data: data,
      );

      if (response.statusCode == 200) {
        return DishModel.fromJson(response.data['data']);
      }
      throw Exception('Erro ao atualizar prato');
    } catch (e) {
      rethrow;
    }
  }

  /// Deletar prato
  Future<void> deleteDish(String dishId) async {
    try {
      final response = await dio.delete(
        '${ApiConstants.adminBase}/dishes/$dishId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erro ao deletar prato');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Ativar/Desativar prato
  Future<DishModel> toggleDishAvailability(String dishId) async {
    try {
      final dish = await getDishDetails(dishId);
      return updateDish(dishId, {'isActive': !dish.isActive});
    } catch (e) {
      rethrow;
    }
  }
}
