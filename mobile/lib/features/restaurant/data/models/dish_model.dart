import 'package:freezed_annotation/freezed_annotation.dart';

part 'dish_model.freezed.dart';
part 'dish_model.g.dart';

@freezed
class DishModel with _$DishModel {
  const factory DishModel({
    required String id,
    required String restaurantId,
    required String name,
    String? description,
    required double price,
    required String category,
    String? subcategory,
    String? imageUrl,
    @Default(true) bool showInFeed,
    DateTime? availabilityStart,
    DateTime? availabilityEnd,
    required bool isActive,
    DateTime? deactivatedAt,
    required double ratingAverage,
    required int ratingCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DishModel;

  factory DishModel.fromJson(Map<String, dynamic> json) =>
      _$DishModelFromJson(json);
}
