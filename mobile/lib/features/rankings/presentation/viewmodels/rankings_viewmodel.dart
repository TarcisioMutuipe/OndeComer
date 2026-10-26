import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:onde_comer_em_salvador/core/constants/api_constants.dart';
import 'package:onde_comer_em_salvador/core/network/dio_client.dart';

class RankingsState {
  final bool isLoading;
  final List<Map<String, dynamic>> topRestaurants;
  final List<Map<String, dynamic>> topDishes;
  final List<Map<String, dynamic>> trendingDishes;
  final List<Map<String, dynamic>> featuredPromotions;
  final String? error;

  const RankingsState({
    this.isLoading = false,
    this.topRestaurants = const [],
    this.topDishes = const [],
    this.trendingDishes = const [],
    this.featuredPromotions = const [],
    this.error,
  });

  RankingsState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? topRestaurants,
    List<Map<String, dynamic>>? topDishes,
    List<Map<String, dynamic>>? trendingDishes,
    List<Map<String, dynamic>>? featuredPromotions,
    String? error,
  }) =>
      RankingsState(
        isLoading: isLoading ?? this.isLoading,
        topRestaurants: topRestaurants ?? this.topRestaurants,
        topDishes: topDishes ?? this.topDishes,
        trendingDishes: trendingDishes ?? this.trendingDishes,
        featuredPromotions: featuredPromotions ?? this.featuredPromotions,
        error: error,
      );
}

class RankingsViewModel extends StateNotifier<RankingsState> {
  final Dio _dio;
  RankingsViewModel(this._dio) : super(const RankingsState());

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _dio.get('${ApiConstants.topRestaurants}?period=week&limit=10'),
        _dio.get('${ApiConstants.topDishes}?period=week&limit=10'),
        _dio.get('${ApiConstants.trendingDishes}?limit=10'),
        _dio.get('${ApiConstants.featuredPromotions}?limit=5'),
      ]);

      state = state.copyWith(
        isLoading: false,
        topRestaurants: _parseList(results[0].data),
        topDishes: _parseList(results[1].data),
        trendingDishes: _parseList(results[2].data),
        featuredPromotions: _parseList(results[3].data),
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Erro ao carregar rankings',
      );
    }
  }

  List<Map<String, dynamic>> _parseList(dynamic data) {
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }
}

final rankingsViewModelProvider =
    StateNotifierProvider<RankingsViewModel, RankingsState>((ref) {
  final dio = ref.watch(dioProvider);
  return RankingsViewModel(dio);
});
