// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommentModelImpl _$$CommentModelImplFromJson(Map<String, dynamic> json) =>
    _$CommentModelImpl(
      id: json['id'] as String,
      dishId: json['dishId'] as String,
      dishName: json['dishName'] as String,
      text: json['text'] as String,
      status: json['status'] as String,
      userName: json['userName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$CommentModelImplToJson(_$CommentModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'dishId': instance.dishId,
      'dishName': instance.dishName,
      'text': instance.text,
      'status': instance.status,
      'userName': instance.userName,
      'createdAt': instance.createdAt.toIso8601String(),
    };
