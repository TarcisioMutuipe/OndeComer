import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/dashboard_overview_model.dart';
import '../models/dish_metric_model.dart';
import '../models/hour_metric_model.dart';
import '../models/comment_metric_model.dart';

final dashboardDatasourceProvider = Provider<DashboardRemoteDatasource>((ref) {
  return DashboardRemoteDatasource(ref.watch(dioProvider));
});

class DashboardRemoteDatasource {
  final Dio _dio;

  DashboardRemoteDatasource(this._dio);

  Future<DashboardOverview> getOverview(String restaurantId) async {
    final response = await _dio.get(
      ApiConstants.dashboardOverview(restaurantId),
    );
    return DashboardOverview.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<DishMetric>> getDishMetrics(String restaurantId) async {
    final response = await _dio.get(
      ApiConstants.dashboardDishMetrics(restaurantId),
    );
    return (response.data as List<dynamic>)
        .map((e) => DishMetric.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<HourMetric>> getHourMetrics(String restaurantId) async {
    final response = await _dio.get(
      ApiConstants.dashboardHourMetrics(restaurantId),
    );
    return (response.data as List<dynamic>)
        .map((e) => HourMetric.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommentMetric> getCommentMetrics(String restaurantId) async {
    final response = await _dio.get(
      ApiConstants.dashboardCommentMetrics(restaurantId),
    );
    return CommentMetric.fromJson(response.data as Map<String, dynamic>);
  }
}
