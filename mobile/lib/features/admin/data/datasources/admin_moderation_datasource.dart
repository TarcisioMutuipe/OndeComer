import 'package:dio/dio.dart';
import 'package:onde_comer_em_salvador/core/constants/api_constants.dart';

class AdminModerationDataSource {
  final Dio dio;

  AdminModerationDataSource({required this.dio});

  /// Remover um comentário
  Future<void> deleteComment(String commentId) async {
    try {
      final response = await dio.delete(
        '${ApiConstants.adminBase}/comments/$commentId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erro ao deletar comentário');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Remover uma avaliação
  Future<void> deleteReview(String reviewId) async {
    try {
      final response = await dio.delete(
        '${ApiConstants.adminBase}/reviews/$reviewId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erro ao deletar avaliação');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Bloquear um usuário
  Future<void> blockUser(String userId, String reason) async {
    try {
      final response = await dio.put(
        '${ApiConstants.adminBase}/users/$userId/block',
        data: {'reason': reason},
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao bloquear usuário');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Desbloquear um usuário
  Future<void> unblockUser(String userId) async {
    try {
      final response = await dio.put(
        '${ApiConstants.adminBase}/users/$userId/unblock',
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao desbloquear usuário');
      }
    } catch (e) {
      rethrow;
    }
  }
}
