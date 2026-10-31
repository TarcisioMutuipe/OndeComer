// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dish_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DishModelImpl _$$DishModelImplFromJson(Map<String, dynamic> json) =>
    _$DishModelImpl(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      imageUrl: json['imageUrl'] as String?,
      showInFeed: json['showInFeed'] as bool? ?? true,
      availabilityStart: json['availabilityStart'] == null
          ? null
          : DateTime.parse(json['availabilityStart'] as String),
      availabilityEnd: json['availabilityEnd'] == null
          ? null
          : DateTime.parse(json['availabilityEnd'] as String),
      isActive: json['isActive'] as bool,
      deactivatedAt: json['deactivatedAt'] == null
          ? null
          : DateTime.parse(json['deactivatedAt'] as String),
      ratingAverage: (json['ratingAverage'] as num).toDouble(),
      ratingCount: (json['ratingCount'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$DishModelImplToJson(_$DishModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'restaurantId': instance.restaurantId,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'imageUrl': instance.imageUrl,
      'showInFeed': instance.showInFeed,
      'availabilityStart': instance.availabilityStart?.toIso8601String(),
      'availabilityEnd': instance.availabilityEnd?.toIso8601String(),
      'isActive': instance.isActive,
      'deactivatedAt': instance.deactivatedAt?.toIso8601String(),
      'ratingAverage': instance.ratingAverage,
      'ratingCount': instance.ratingCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
