import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../../data/models/promotion_model.dart';
import '../../data/models/dish_feed_post_model.dart';
import '../../data/models/city_event_model.dart';
import '../../../../core/network/dio_client.dart' show friendlyErrorMessage;

final feedViewModelProvider =
    StateNotifierProvider<FeedViewModel, FeedState>((ref) {
  return FeedViewModel(ref.watch(feedRemoteDatasourceProvider));
});

class FeedState {
  final List<PromotionModel> promotions;
  final List<DishFeedPostModel> dishPosts;
  final List<CityEventModel> events;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int page;
  final bool hasMore;

  const FeedState({
    this.promotions = const [],
    this.dishPosts = const [],
    this.events = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
  });

  FeedState copyWith({
    List<PromotionModel>? promotions,
    List<DishFeedPostModel>? dishPosts,
    List<CityEventModel>? events,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? page,
    bool? hasMore,
  }) =>
      FeedState(
        promotions: promotions ?? this.promotions,
        dishPosts: dishPosts ?? this.dishPosts,
        events: events ?? this.events,
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
        _datasource.getEvents(),
      ]);
      final promotions = results[0] as List<PromotionModel>;
      final dishPosts = results[1] as List<DishFeedPostModel>;
      final events = results[2] as List<CityEventModel>;

      state = state.copyWith(
        promotions: refresh ? promotions : [...state.promotions, ...promotions],
        dishPosts: refresh ? dishPosts : [...state.dishPosts, ...dishPosts],
        events: events,
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

  Future<void> reactToEvent(String eventId, bool isLike) async {
    final eventIndex = state.events.indexWhere((e) => e.id == eventId);
    if (eventIndex == -1) return;

    final oldEvent = state.events[eventIndex];
    // Optimistic calculation
    int newLikes = oldEvent.likesCount;
    int newDislikes = oldEvent.dislikesCount;
    bool? newReaction;

    if (oldEvent.userReaction == isLike) {
      // Toggle off
      newReaction = null;
      if (isLike) newLikes = (newLikes - 1).clamp(0, 999999);
      else newDislikes = (newDislikes - 1).clamp(0, 999999);
    } else if (oldEvent.userReaction != null) {
      // Switching
      newReaction = isLike;
      if (isLike) {
        newLikes++;
        newDislikes = (newDislikes - 1).clamp(0, 999999);
      } else {
        newDislikes++;
        newLikes = (newLikes - 1).clamp(0, 999999);
      }
    } else {
      // First reaction
      newReaction = isLike;
      if (isLike) newLikes++;
      else newDislikes++;
    }

    final updatedEvents = List<CityEventModel>.from(state.events);
    updatedEvents[eventIndex] = oldEvent.copyWith(
      likesCount: newLikes,
      dislikesCount: newDislikes,
      userReaction: newReaction,
      clearReaction: newReaction == null,
    );
    state = state.copyWith(events: updatedEvents);

    try {
      final res = await _datasource.reactToEvent(eventId, isLike);
      final serverLikes = (res['likesCount'] as num?)?.toInt() ?? newLikes;
      final serverDislikes = (res['dislikesCount'] as num?)?.toInt() ?? newDislikes;
      final serverReaction = res['currentReaction'] as bool?;

      final syncEvents = List<CityEventModel>.from(state.events);
      syncEvents[eventIndex] = syncEvents[eventIndex].copyWith(
        likesCount: serverLikes,
        dislikesCount: serverDislikes,
        userReaction: serverReaction,
        clearReaction: serverReaction == null,
      );
      state = state.copyWith(events: syncEvents);
    } catch (_) {
      // Rollback on network failure
      final rollbackEvents = List<CityEventModel>.from(state.events);
      rollbackEvents[eventIndex] = oldEvent;
      state = state.copyWith(events: rollbackEvents);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _datasource.deleteEvent(eventId);
      state = state.copyWith(
        events: state.events.where((e) => e.id != eventId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: friendlyErrorMessage(e));
    }
  }
}
