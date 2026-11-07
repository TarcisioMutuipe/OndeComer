import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/promotion_model.dart';
import '../models/promotion_ticket_model.dart';
import '../models/dish_feed_post_model.dart';
import '../models/city_event_model.dart';

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

  Future<List<DishFeedPostModel>> getDishPosts(
      {int page = 1, int pageSize = 20}) async {
    final response = await _dio.get(
      ApiConstants.dishFeed,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List? ?? [])
        .map((item) => DishFeedPostModel.fromJson(item as Map<String, dynamic>))
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
      if (expiresAt != null) 'claimEndsAt': expiresAt.toUtc().toIso8601String(),
    });
    return PromotionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> claimPromotion(String promotionId) async {
    final response = await _dio.post(ApiConstants.claimPromotion(promotionId));
    return response.data as Map<String, dynamic>;
  }

  Future<List<PromotionTicketModel>> getMyTickets() async {
    final response = await _dio.get(ApiConstants.myPromotionTickets);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => PromotionTicketModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PromotionTicketModel>> getRestaurantTickets() async {
    final response = await _dio.get(ApiConstants.restaurantPromotionTickets);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => PromotionTicketModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> finalizePromotionTicket(
      String qrCodeToken) async {
    final response = await _dio.post(
      ApiConstants.finalizePromotionTicket,
      data: {'qrCodeToken': qrCodeToken},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> deletePromotion(String promotionId) async {
    await _dio.delete('${ApiConstants.promotionsBase}/$promotionId');
  }

  // City Events & News (Feature 1)
  Future<List<CityEventModel>> getEvents() async {
    final response = await _dio.get(ApiConstants.eventsBase);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => CityEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> reactToEvent(String eventId, bool isLike) async {
    final response = await _dio.post(
      ApiConstants.eventReact(eventId),
      data: {'isLike': isLike},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<CityEventModel> createEvent({
    required String title,
    required String description,
    required String imageUrl,
    String? youTubeVideoUrl,
    String? locationOrAddress,
    DateTime? eventDate,
    String? restaurantId,
  }) async {
    final response = await _dio.post(ApiConstants.eventsBase, data: {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      if (youTubeVideoUrl != null && youTubeVideoUrl.isNotEmpty)
        'youTubeVideoUrl': youTubeVideoUrl,
      if (locationOrAddress != null && locationOrAddress.isNotEmpty)
        'locationOrAddress': locationOrAddress,
      if (eventDate != null) 'eventDate': eventDate.toIso8601String(),
      if (restaurantId != null && restaurantId.isNotEmpty)
        'restaurantId': restaurantId,
    });
    return CityEventModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteEvent(String eventId) async {
    await _dio.delete(ApiConstants.eventById(eventId));
  }
}
