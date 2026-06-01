import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/notification_preference_model.dart';

final notificationDatasourceProvider =
    Provider<NotificationRemoteDatasource>((ref) {
  return NotificationRemoteDatasource(ref.watch(dioProvider));
});

class NotificationRemoteDatasource {
  final Dio _dio;

  NotificationRemoteDatasource(this._dio);

  Future<void> registerDevice({
    required String platform,
    String? fcmToken,
    String? apnsToken,
  }) async {
    await _dio.post(
      ApiConstants.notificationsRegisterDevice,
      data: {
        'platform': platform,
        if (fcmToken != null) 'fcmToken': fcmToken,
        if (apnsToken != null) 'apnsToken': apnsToken,
      },
    );
  }

  Future<void> unregisterDevice({String? fcmToken}) async {
    await _dio.post(
      ApiConstants.notificationsUnregisterDevice,
      data: {'fcmToken': fcmToken},
    );
  }

  Future<NotificationPreference> getPreferences() async {
    final response = await _dio.get(ApiConstants.notificationsPreferences);
    return NotificationPreference.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<NotificationPreference> updatePreferences(
      NotificationPreference prefs) async {
    final response = await _dio.put(
      ApiConstants.notificationsPreferences,
      data: prefs.toJson(),
    );
    return NotificationPreference.fromJson(
        response.data as Map<String, dynamic>);
  }
}
