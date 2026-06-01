import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/restaurant_list_datasource.dart';
import '../../data/models/restaurant_model.dart';

final restaurantListViewModelProvider =
    StateNotifierProvider<RestaurantListViewModel, RestaurantListState>((ref) {
  return RestaurantListViewModel(ref.watch(restaurantListDatasourceProvider));
});

final restaurantDetailProvider =
    FutureProvider.family<RestaurantModel, String>((ref, id) async {
  return ref.watch(restaurantListDatasourceProvider).getById(id);
});

class RestaurantListState {
  final List<RestaurantModel> restaurants;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? search;
  final String? category;
  final int page;
  final bool hasMore;

  const RestaurantListState({
    this.restaurants = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.search,
    this.category,
    this.page = 1,
    this.hasMore = true,
  });

  RestaurantListState copyWith({
    List<RestaurantModel>? restaurants,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? search,
    String? category,
    int? page,
    bool? hasMore,
  }) =>
      RestaurantListState(
        restaurants: restaurants ?? this.restaurants,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error,
        search: search ?? this.search,
        category: category ?? this.category,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
      );
}

class RestaurantListViewModel extends StateNotifier<RestaurantListState> {
  final RestaurantListDatasource _datasource;

  RestaurantListViewModel(this._datasource)
      : super(const RestaurantListState());

  Future<void> load({bool refresh = false}) async {
    if (!refresh && (state.isLoading || state.isLoadingMore || !state.hasMore))
      return;

    final page = refresh ? 1 : state.page;
    if (refresh) {
      state =
          state.copyWith(isLoading: true, error: null, page: 1, hasMore: true);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final data = await _datasource.getRestaurants(
        search: state.search,
        category: state.category,
        page: page,
      );
      final itemsJson = data['items'] as List? ?? [];
      final items = itemsJson
          .map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = data['totalCount'] as int? ?? 0;

      state = state.copyWith(
        restaurants: refresh ? items : [...state.restaurants, ...items],
        isLoading: false,
        isLoadingMore: false,
        page: page + 1,
        hasMore: items.length >= 20 &&
            (refresh ? items.length : state.restaurants.length + items.length) <
                total,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, isLoadingMore: false, error: e.toString());
    }
  }

  void setSearch(String? search) {
    state =
        state.copyWith(search: search, restaurants: [], page: 1, hasMore: true);
    load(refresh: true);
  }

  void setCategory(String? category) {
    state = state.copyWith(
        category: category, restaurants: [], page: 1, hasMore: true);
    load(refresh: true);
  }
}
