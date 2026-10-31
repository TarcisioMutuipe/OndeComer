import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../../data/models/promotion_model.dart';
import '../../data/models/dish_feed_post_model.dart';
import '../../../../core/network/dio_client.dart' show friendlyErrorMessage;

final feedViewModelProvider =
    StateNotifierProvider<FeedViewModel, FeedState>((ref) {
  return FeedViewModel(ref.watch(feedRemoteDatasourceProvider));
});

class FeedState {
  final List<PromotionModel> promotions;
  final List<DishFeedPostModel> dishPosts;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int page;
  final bool hasMore;

  const FeedState({
    this.promotions = const [],
    this.dishPosts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
  });

  FeedState copyWith({
    List<PromotionModel>? promotions,
    List<DishFeedPostModel>? dishPosts,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? page,
    bool? hasMore,
  }) =>
      FeedState(
        promotions: promotions ?? this.promotions,
        dishPosts: dishPosts ?? this.dishPosts,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
      );
}

class FeedViewModel extends StateNotifier<FeedState> {
  final FeedRemoteDatasource _datasource;

  FeedViewModel(this._datasource) : super(const FeedState());

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      state =
          state.copyWith(isLoading: true, error: null, page: 1, hasMore: true);
    } else {
      if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
      state = state.copyWith(isLoadingMore: true);
    }
    try {
      final page = refresh ? 1 : state.page;
      final results = await Future.wait([
        _datasource.getPromotions(page: page),
        _datasource.getDishPosts(page: page),
      ]);
      final promotions = results[0] as List<PromotionModel>;
      final dishPosts = results[1] as List<DishFeedPostModel>;
      state = state.copyWith(
        promotions: refresh ? promotions : [...state.promotions, ...promotions],
        dishPosts: refresh ? dishPosts : [...state.dishPosts, ...dishPosts],
        isLoading: false,
        isLoadingMore: false,
        page: page + 1,
        hasMore: promotions.length >= 20 || dishPosts.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: friendlyErrorMessage(e));
    }
  }
}
