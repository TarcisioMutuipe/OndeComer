import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/promotion_model.dart';

final feedRemoteDatasourceProvider =
    Provider((ref) => FeedRemoteDatasource(ref.watch(dioProvider)));

class FeedRemoteDatasource {
  final Dio _dio;
  FeedRemoteDatasource(this._dio);

  Future<List<PromotionModel>> getPromotions(
      {int page = 1, int pageSize = 20}) async {
    final response = await _dio.get(
      ApiConstants.promotionsBase,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final data = response.data;
    final items =
        data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);
    return items
        .map((e) => PromotionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PromotionModel>> getByRestaurant(String restaurantId) async {
    final response =
        await _dio.get(ApiConstants.promotionsByRestaurant(restaurantId));
    return (response.data as List)
        .map((e) => PromotionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PromotionModel> createPromotion({
    required String title,
    String? description,
    String? imageUrl,
    double? discountPercent,
    DateTime? expiresAt,
  }) async {
    final response = await _dio.post(ApiConstants.promotionsBase, data: {
      'title': title,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      if (discountPercent != null) 'discountPercent': discountPercent,
      if (expiresAt != null) 'expiresAt': expiresAt.toUtc().toIso8601String(),
    });
    return PromotionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePromotion(String promotionId) async {
    await _dio.delete('${ApiConstants.promotionsBase}/$promotionId');
  }
}
