import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/admin_models.dart';
import '../models/promotion_ticket_admin_models.dart';

final adminDatasourceProvider = Provider<AdminRemoteDatasource>((ref) {
  return AdminRemoteDatasource(ref.watch(dioProvider));
});

class AdminRemoteDatasource {
  final Dio _dio;

  AdminRemoteDatasource(this._dio);

  Future<AdminDashboardModel> getDashboard() async {
    final response = await _dio.get(ApiConstants.adminDashboard);
    return AdminDashboardModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AdminUserModel>> getUsers(
      {String? search, String? profileType, int page = 1}) async {
    final response = await _dio.get(
      ApiConstants.adminUsers,
      queryParameters: {
        'page': page,
        'pageSize': 20,
        if (search != null) 'search': search,
        if (profileType != null) 'profileType': profileType,
      },
    );
    return (response.data as List<dynamic>)
        .map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _dio.put('${ApiConstants.adminUsers}/$userId', data: data);
  }

  Future<void> deleteUser(String userId) async {
    await _dio.delete('${ApiConstants.adminUsers}/$userId');
  }

  Future<List<ModerationLogModel>> getModerationLogs(
      {String? result, int page = 1}) async {
    final response = await _dio.get(
      ApiConstants.adminModerationLogs,
      queryParameters: {
        'page': page,
        'pageSize': 20,
        if (result != null) 'result': result,
      },
    );
    return (response.data as List<dynamic>)
        .map((e) => ModerationLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> reviewModeration(String logId, String decision) async {
    await _dio.post(
      '${ApiConstants.adminModerationLogs}/$logId/review',
      data: {'decision': decision},
    );
  }

  Future<PromotionSettingsModel> getPromotionSettings() async {
    final response =
        await _dio.get('${ApiConstants.adminBase}/promotions/settings');
    return PromotionSettingsModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<PromotionSettingsModel> updatePromotionSettings(
    PromotionSettingsModel settings,
  ) async {
    final response = await _dio.put(
      '${ApiConstants.adminBase}/promotions/settings',
      data: settings.toJson(),
    );
    return PromotionSettingsModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<PendingPromotionPaymentModel>>
      getPendingPromotionPayments() async {
    final response = await _dio.get(
      '${ApiConstants.adminBase}/promotions/pending-payment',
    );
    return (response.data as List<dynamic>)
        .map((item) =>
            PendingPromotionPaymentModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> approvePromotionPayment(String promotionId) async {
    await _dio.post(
      '${ApiConstants.adminBase}/promotions/$promotionId/approve-payment',
    );
  }

  Future<PromotionTicketsSummaryModel> getPromotionTicketsSummary({
    String? restaurantId,
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.adminBase}/promotions/tickets/summary',
      queryParameters: {
        if (restaurantId != null) 'restaurantId': restaurantId,
        if (status != null) 'status': status,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
    );
    return PromotionTicketsSummaryModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<PromotionTicketAdminPageModel> getPromotionTickets({
    String? restaurantId,
    String? status,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.adminBase}/promotions/tickets',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (restaurantId != null) 'restaurantId': restaurantId,
        if (status != null) 'status': status,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
    );
    return PromotionTicketAdminPageModel.fromJson(
        response.data as Map<String, dynamic>);
  }
}
