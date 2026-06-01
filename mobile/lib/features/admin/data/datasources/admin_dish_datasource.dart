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
        '${ApiConstants.adminBase}/dishes',
        queryParameters: {
          'restaurantId': restaurantId,
          'page': page,
          'pageSize': pageSize,
          if (search != null) 'search': search,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data
            .map((json) => DishModel.fromJson(json as Map<String, dynamic>))
            .toList();
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
        '${ApiConstants.adminBase}/dishes/$dishId',
      );

      if (response.statusCode == 200) {
        return DishModel.fromJson(response.data['data']);
      }
      throw Exception('Erro ao carregar prato');
    } catch (e) {
      rethrow;
    }
  }

  /// Criar novo prato
  Future<DishModel> createDish(Map<String, dynamic> data) async {
    try {
      final response = await dio.post(
        '${ApiConstants.adminBase}/dishes',
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DishModel.fromJson(response.data['data']);
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
      final response = await dio.put(
        '${ApiConstants.adminBase}/dishes/$dishId/toggle-availability',
      );

      if (response.statusCode == 200) {
        return DishModel.fromJson(response.data['data']);
      }
      throw Exception('Erro ao alternar disponibilidade do prato');
    } catch (e) {
      rethrow;
    }
  }
}
