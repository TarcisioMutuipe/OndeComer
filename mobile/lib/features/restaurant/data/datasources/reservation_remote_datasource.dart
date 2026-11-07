import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/reservation_model.dart';

final reservationRemoteDatasourceProvider =
    Provider((ref) => ReservationRemoteDatasource(ref.watch(dioProvider)));

class ReservationRemoteDatasource {
  final Dio _dio;
  ReservationRemoteDatasource(this._dio);

  Future<ReservationModel> createReservation({
    required String restaurantId,
    required String customerName,
    required String customerPhone,
    required DateTime reservationDate,
    required String timeSlot,
    required int partySize,
    String? notes,
  }) async {
    final response = await _dio.post(
      ApiConstants.restaurantReservations(restaurantId),
      data: {
        'customerName': customerName,
        'customerPhone': customerPhone,
        'reservationDate': reservationDate.toIso8601String(),
        'timeSlot': timeSlot,
        'partySize': partySize,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return ReservationModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ReservationModel>> getMyReservations() async {
    final response = await _dio.get(ApiConstants.myReservations);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => ReservationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReservationModel>> getRestaurantReservations({
    required String restaurantId,
    DateTime? date,
    int? status,
  }) async {
    final response = await _dio.get(
      ApiConstants.restaurantReservations(restaurantId),
      queryParameters: {
        if (date != null) 'date': date.toIso8601String(),
        if (status != null) 'status': status,
      },
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => ReservationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReservationModel> updateStatus({
    required String reservationId,
    required int status,
    String? cancellationReason,
  }) async {
    final response = await _dio.put(
      ApiConstants.reservationStatus(reservationId),
      data: {
        'status': status,
        if (cancellationReason != null) 'cancellationReason': cancellationReason,
      },
    );
    return ReservationModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ReservationModel> cancelReservation({
    required String reservationId,
    String? reason,
  }) async {
    final response = await _dio.put(
      ApiConstants.cancelReservation(reservationId),
      queryParameters: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return ReservationModel.fromJson(response.data as Map<String, dynamic>);
  }
}

