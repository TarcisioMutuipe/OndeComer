import 'package:freezed_annotation/freezed_annotation.dart';

part 'restaurant_model.freezed.dart';
part 'restaurant_model.g.dart';

@freezed
class RestaurantModel with _$RestaurantModel {
  const factory RestaurantModel({
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
    String? youTubeVideoUrl,
    required bool isActive,
    required String openingHours,
    @Default(0) int dishCount,
    required DateTime createdAt,
  }) = _RestaurantModel;

  factory RestaurantModel.fromJson(Map<String, dynamic> json) =>
      _$RestaurantModelFromJson(json);
}
