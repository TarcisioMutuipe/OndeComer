import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/checkin_model.dart';

final checkInDatasourceProvider = Provider<CheckInRemoteDatasource>((ref) {
  return CheckInRemoteDatasource(ref.watch(dioProvider));
});

class CheckInRemoteDatasource {
  final Dio _dio;

  CheckInRemoteDatasource(this._dio);

  Future<CheckInModel> doCheckIn({
    required String restaurantId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.post(
      ApiConstants.checkInsBase,
      data: {
        'restaurantId': restaurantId,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return CheckInModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CheckInHistoryModel> getHistory(
      {int page = 1, int pageSize = 20}) async {
    final response = await _dio.get(
      ApiConstants.checkInHistory,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return CheckInHistoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<int> getPoints() async {
    final response = await _dio.get(ApiConstants.checkInPoints);
    return (response.data as Map<String, dynamic>)['totalPoints'] as int;
  }

  Future<QrCodeModel> getQrData(String restaurantId) async {
    final response = await _dio.get(ApiConstants.checkInQr(restaurantId));
    return QrCodeModel.fromJson(response.data as Map<String, dynamic>);
  }
}
