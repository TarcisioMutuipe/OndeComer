import 'package:freezed_annotation/freezed_annotation.dart';
import 'wishlist_item_model.dart';

part 'wishlist_model.freezed.dart';
part 'wishlist_model.g.dart';

@freezed
class WishlistModel with _$WishlistModel {
  const factory WishlistModel({
    required String id,
    required String userId,
    required String name,
    String? description,
    required bool isPublic,
    String? shareToken,
    String? shareUrl,
    @Default(0) int itemCount,
    @Default([]) List<WishlistItemModel> items,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _WishlistModel;

  factory WishlistModel.fromJson(Map<String, dynamic> json) =>
      _$WishlistModelFromJson(json);
}
