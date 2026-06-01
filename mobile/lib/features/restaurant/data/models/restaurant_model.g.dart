// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RestaurantModelImpl _$$RestaurantModelImplFromJson(
        Map<String, dynamic> json) =>
    _$RestaurantModelImpl(
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
      youTubeVideoUrl: json['youTubeVideoUrl'] as String?,
      isActive: json['isActive'] as bool,
      openingHours: json['openingHours'] as String,
      dishCount: (json['dishCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$RestaurantModelImplToJson(
        _$RestaurantModelImpl instance) =>
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
      'youTubeVideoUrl': instance.youTubeVideoUrl,
      'isActive': instance.isActive,
      'openingHours': instance.openingHours,
      'dishCount': instance.dishCount,
      'createdAt': instance.createdAt.toIso8601String(),
    };
