import 'package:freezed_annotation/freezed_annotation.dart';

part 'wishlist_item_model.freezed.dart';
part 'wishlist_item_model.g.dart';

@freezed
class WishlistItemModel with _$WishlistItemModel {
  const factory WishlistItemModel({
    required String id,
    required String wishlistId,
    String? restaurantId,
    String? restaurantName,
    String? restaurantLogoUrl,
    String? dishId,
    String? dishName,
    String? dishImageUrl,
    String? note,
    required DateTime createdAt,
  }) = _WishlistItemModel;

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) =>
      _$WishlistItemModelFromJson(json);
}
