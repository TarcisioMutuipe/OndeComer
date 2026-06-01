import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/models/dashboard_overview_model.dart';
import '../../data/models/dish_metric_model.dart';
import '../../data/models/hour_metric_model.dart';
import '../../data/models/comment_metric_model.dart';
import '../../../../core/network/dio_client.dart' show friendlyErrorMessage;

class DashboardMetricsState {
  final DashboardOverview? overview;
  final List<DishMetric> dishMetrics;
  final List<HourMetric> hourMetrics;
  final CommentMetric? commentMetrics;
  final bool isLoading;
  final String? error;

  DashboardMetricsState({
    this.overview,
    this.dishMetrics = const [],
    this.hourMetrics = const [],
    this.commentMetrics,
    this.isLoading = false,
    this.error,
  });

  DashboardMetricsState copyWith({
    DashboardOverview? overview,
    List<DishMetric>? dishMetrics,
    List<HourMetric>? hourMetrics,
    CommentMetric? commentMetrics,
    bool? isLoading,
    String? error,
  }) {
    return DashboardMetricsState(
      overview: overview ?? this.overview,
      dishMetrics: dishMetrics ?? this.dishMetrics,
      hourMetrics: hourMetrics ?? this.hourMetrics,
      commentMetrics: commentMetrics ?? this.commentMetrics,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DashboardMetricsNotifier extends StateNotifier<DashboardMetricsState> {
  final DashboardRemoteDatasource _datasource;
  Timer? _refreshTimer;

  DashboardMetricsNotifier(this._datasource) : super(DashboardMetricsState());

  Future<void> loadAll(String restaurantId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _datasource.getOverview(restaurantId),
        _datasource.getDishMetrics(restaurantId),
        _datasource.getHourMetrics(restaurantId),
        _datasource.getCommentMetrics(restaurantId),
      ]);

      state = state.copyWith(
        overview: results[0] as DashboardOverview,
        dishMetrics: results[1] as List<DishMetric>,
        hourMetrics: results[2] as List<HourMetric>,
        commentMetrics: results[3] as CommentMetric,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: friendlyErrorMessage(e));
    }
  }

  void startPeriodicRefresh(String restaurantId) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => loadAll(restaurantId),
    );
  }

  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final dashboardMetricsProvider = StateNotifierProvider.autoDispose<
    DashboardMetricsNotifier, DashboardMetricsState>((ref) {
  final datasource = ref.watch(dashboardDatasourceProvider);
  return DashboardMetricsNotifier(datasource);
});
