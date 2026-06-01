// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FavoriteModelImpl _$$FavoriteModelImplFromJson(Map<String, dynamic> json) =>
    _$FavoriteModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      restaurantId: json['restaurantId'] as String?,
      restaurantName: json['restaurantName'] as String?,
      restaurantLogoUrl: json['restaurantLogoUrl'] as String?,
      dishId: json['dishId'] as String?,
      dishName: json['dishName'] as String?,
      dishImageUrl: json['dishImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$FavoriteModelImplToJson(_$FavoriteModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'restaurantId': instance.restaurantId,
      'restaurantName': instance.restaurantName,
      'restaurantLogoUrl': instance.restaurantLogoUrl,
      'dishId': instance.dishId,
      'dishName': instance.dishName,
      'dishImageUrl': instance.dishImageUrl,
      'createdAt': instance.createdAt.toIso8601String(),
    };
