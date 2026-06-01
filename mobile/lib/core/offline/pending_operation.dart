import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

part 'pending_operation.g.dart';

@HiveType(typeId: 0)
class PendingOperation extends HiveObject {
  @HiveField(0)
  late String clientId; // UUID — idempotency key

  @HiveField(1)
  late String operationType; // 'create_review' | 'create_comment'

  @HiveField(2)
  late String entityType; // 'review' | 'comment'

  @HiveField(3)
  String? entityId;

  @HiveField(4)
  late String payload; // JSON string

  @HiveField(5)
  late int retryCount;

  @HiveField(6)
  late DateTime timestamp;

  PendingOperation({
    required this.clientId,
    required this.operationType,
    required this.entityType,
    this.entityId,
    required this.payload,
    this.retryCount = 0,
    required this.timestamp,
  });

  Map<String, dynamic> toServerJson() => {
        'clientId': clientId,
        'operationType': operationType,
        'entityType': entityType,
        'entityId': entityId,
        'payload': payload,
        'timestamp': timestamp.toUtc().toIso8601String(),
      };

  static PendingOperation review({
    required String clientId,
    required String dishId,
    required int rating,
  }) =>
      PendingOperation(
        clientId: clientId,
        operationType: 'create_review',
        entityType: 'review',
        payload: jsonEncode({'dishId': dishId, 'rating': rating}),
        timestamp: DateTime.now().toUtc(),
      );

  static PendingOperation comment({
    required String clientId,
    required String dishId,
    required String text,
  }) =>
      PendingOperation(
        clientId: clientId,
        operationType: 'create_comment',
        entityType: 'comment',
        payload: jsonEncode({'dishId': dishId, 'text': text}),
        timestamp: DateTime.now().toUtc(),
      );
}
