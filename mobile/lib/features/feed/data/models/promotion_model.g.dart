// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PromotionModelImpl _$$PromotionModelImplFromJson(Map<String, dynamic> json) =>
    _$PromotionModelImpl(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      restaurantName: json['restaurantName'] as String,
      restaurantLogoUrl: json['restaurantLogoUrl'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      discountPercent: (json['discountPercent'] as num?)?.toDouble(),
      totalTickets: (json['totalTickets'] as num).toInt(),
      remainingTickets: (json['remainingTickets'] as num).toInt(),
      scope: json['scope'] as String,
      claimStartsAt: DateTime.parse(json['claimStartsAt'] as String),
      claimEndsAt: DateTime.parse(json['claimEndsAt'] as String),
      ticketValidityDays: (json['ticketValidityDays'] as num).toInt(),
      canClaim: json['canClaim'] as bool,
      pixKey: json['pixKey'] as String?,
      targetDishNames: (json['targetDishNames'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$PromotionModelImplToJson(
        _$PromotionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'restaurantId': instance.restaurantId,
      'restaurantName': instance.restaurantName,
      'restaurantLogoUrl': instance.restaurantLogoUrl,
      'title': instance.title,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'discountPercent': instance.discountPercent,
      'totalTickets': instance.totalTickets,
      'remainingTickets': instance.remainingTickets,
      'scope': instance.scope,
      'claimStartsAt': instance.claimStartsAt.toIso8601String(),
      'claimEndsAt': instance.claimEndsAt.toIso8601String(),
      'ticketValidityDays': instance.ticketValidityDays,
      'canClaim': instance.canClaim,
      'pixKey': instance.pixKey,
      'targetDishNames': instance.targetDishNames,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };
