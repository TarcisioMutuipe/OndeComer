import 'package:freezed_annotation/freezed_annotation.dart';

part 'restaurant_search_result_model.freezed.dart';
part 'restaurant_search_result_model.g.dart';

@freezed
class RestaurantSearchResultModel with _$RestaurantSearchResultModel {
  const factory RestaurantSearchResultModel({
    required String id,
    required String ownerUserId,
    required String name,
    String? description,
    required String address,
    @Default('Salvador') String city,
    required double latitude,
    required double longitude,
    required String category,
    String? logoUrl,
    String? coverUrl,
    String? instagramUrl,
    required bool isActive,
    required String openingHours,
    @Default(0) int dishCount,
    required DateTime createdAt,
    double? distanceKm,
    @Default(0.0) double averageRating,
    @Default(false) bool isCurrentlyOpen,
    double? minDishPrice,
  }) = _RestaurantSearchResultModel;

  factory RestaurantSearchResultModel.fromJson(Map<String, dynamic> json) =>
      _$RestaurantSearchResultModelFromJson(json);
}
