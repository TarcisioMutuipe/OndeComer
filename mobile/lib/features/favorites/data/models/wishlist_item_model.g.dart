// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wishlist_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WishlistItemModelImpl _$$WishlistItemModelImplFromJson(
        Map<String, dynamic> json) =>
    _$WishlistItemModelImpl(
      id: json['id'] as String,
      wishlistId: json['wishlistId'] as String,
      restaurantId: json['restaurantId'] as String?,
      restaurantName: json['restaurantName'] as String?,
      restaurantLogoUrl: json['restaurantLogoUrl'] as String?,
      dishId: json['dishId'] as String?,
      dishName: json['dishName'] as String?,
      dishImageUrl: json['dishImageUrl'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$WishlistItemModelImplToJson(
        _$WishlistItemModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'wishlistId': instance.wishlistId,
      'restaurantId': instance.restaurantId,
      'restaurantName': instance.restaurantName,
      'restaurantLogoUrl': instance.restaurantLogoUrl,
      'dishId': instance.dishId,
      'dishName': instance.dishName,
      'dishImageUrl': instance.dishImageUrl,
      'note': instance.note,
      'createdAt': instance.createdAt.toIso8601String(),
    };
