// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_search_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RestaurantSearchResultModelImpl _$$RestaurantSearchResultModelImplFromJson(
        Map<String, dynamic> json) =>
    _$RestaurantSearchResultModelImpl(
      id: json['id'] as String,
      ownerUserId: json['ownerUserId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String,
      city: json['city'] as String? ?? 'Salvador',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      category: json['category'] as String,
      logoUrl: json['logoUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
      isActive: json['isActive'] as bool,
      openingHours: json['openingHours'] as String,
      dishCount: (json['dishCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      isCurrentlyOpen: json['isCurrentlyOpen'] as bool? ?? false,
      minDishPrice: (json['minDishPrice'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$RestaurantSearchResultModelImplToJson(
        _$RestaurantSearchResultModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ownerUserId': instance.ownerUserId,
      'name': instance.name,
      'description': instance.description,
      'address': instance.address,
      'city': instance.city,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'category': instance.category,
      'logoUrl': instance.logoUrl,
      'coverUrl': instance.coverUrl,
      'instagramUrl': instance.instagramUrl,
      'isActive': instance.isActive,
      'openingHours': instance.openingHours,
      'dishCount': instance.dishCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'distanceKm': instance.distanceKm,
      'averageRating': instance.averageRating,
      'isCurrentlyOpen': instance.isCurrentlyOpen,
      'minDishPrice': instance.minDishPrice,
    };
