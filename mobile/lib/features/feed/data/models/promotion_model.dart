import 'package:freezed_annotation/freezed_annotation.dart';

part 'promotion_model.freezed.dart';
part 'promotion_model.g.dart';

@freezed
class PromotionModel with _$PromotionModel {
  const factory PromotionModel({
    required String id,
    required String restaurantId,
    required String restaurantName,
    String? restaurantLogoUrl,
    required String title,
    String? description,
    String? imageUrl,
    double? discountPercent,
    DateTime? expiresAt,
    required DateTime createdAt,
  }) = _PromotionModel;

  factory PromotionModel.fromJson(Map<String, dynamic> json) =>
      _$PromotionModelFromJson(json);
}
