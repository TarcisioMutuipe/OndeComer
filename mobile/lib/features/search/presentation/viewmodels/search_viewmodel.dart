import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../search/data/datasources/search_datasource.dart';
import '../../../search/data/models/restaurant_search_result_model.dart';

// ─── State ──────────────────────────────────────────────────────────────────

class SearchState {
  final List<RestaurantSearchResultModel> results;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int page;
  final bool hasMore;

  // Filters
  final String? query;
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final bool? isOpenNow;
  final String sortBy; // relevance | distance | rating | name
  final String sortOrder; // asc | desc

  // Geo
  final double? userLat;
  final double? userLng;
  final double? radius; // km
  final bool locationPermissionDenied;
  final bool locationLoading;

  // Cache
  final DateTime? cachedAt;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
    this.query,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.isOpenNow,
    this.sortBy = 'relevance',
    this.sortOrder = 'asc',
    this.userLat,
    this.userLng,
    this.radius,
    this.locationPermissionDenied = false,
    this.locationLoading = false,
    this.cachedAt,
  });

  bool get hasActiveFilters =>
      category != null ||
      minPrice != null ||
      maxPrice != null ||
      minRating != null ||
      isOpenNow == true ||
      userLat != null ||
      sortBy != 'relevance';

  SearchState copyWith({
    List<RestaurantSearchResultModel>? results,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error = _sentinel,
    int? page,
    bool? hasMore,
    Object? query = _sentinel,
    Object? category = _sentinel,
    Object? minPrice = _sentinel,
    Object? maxPrice = _sentinel,
    Object? minRating = _sentinel,
    Object? isOpenNow = _sentinel,
    String? sortBy,
    String? sortOrder,
    Object? userLat = _sentinel,
    Object? userLng = _sentinel,
    Object? radius = _sentinel,
    bool? locationPermissionDenied,
    bool? locationLoading,
    Object? cachedAt = _sentinel,
  }) =>
      SearchState(
        results: results ?? this.results,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error == _sentinel ? this.error : error as String?,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        query: query == _sentinel ? this.query : query as String?,
        category: category == _sentinel ? this.category : category as String?,
        minPrice: minPrice == _sentinel ? this.minPrice : minPrice as double?,
        maxPrice: maxPrice == _sentinel ? this.maxPrice : maxPrice as double?,
        minRating:
            minRating == _sentinel ? this.minRating : minRating as double?,
        isOpenNow: isOpenNow == _sentinel ? this.isOpenNow : isOpenNow as bool?,
        sortBy: sortBy ?? this.sortBy,
        sortOrder: sortOrder ?? this.sortOrder,
        userLat: userLat == _sentinel ? this.userLat : userLat as double?,
        userLng: userLng == _sentinel ? this.userLng : userLng as double?,
        radius: radius == _sentinel ? this.radius : radius as double?,
        locationPermissionDenied:
            locationPermissionDenied ?? this.locationPermissionDenied,
        locationLoading: locationLoading ?? this.locationLoading,
        cachedAt: cachedAt == _sentinel ? this.cachedAt : cachedAt as DateTime?,
      );
}

// Sentinel to distinguish "not provided" from explicit null
const _sentinel = Object();

// ─── Cache TTL ──────────────────────────────────────────────────────────────

const _cacheTtl = Duration(minutes: 2);

// ─── Provider ───────────────────────────────────────────────────────────────

final searchViewModelProvider =
    StateNotifierProvider<SearchViewModel, SearchState>((ref) {
  return SearchViewModel(ref.watch(searchDatasourceProvider));
});

// ─── ViewModel ──────────────────────────────────────────────────────────────

class SearchViewModel extends StateNotifier<SearchState> {
  final SearchDatasource _datasource;

  SearchViewModel(this._datasource) : super(const SearchState());

  // ── Geolocation ─────────────────────────────────────────────────────────

  Future<void> requestLocation() async {
    state =
        state.copyWith(locationLoading: true, locationPermissionDenied: false);

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        state = state.copyWith(
          locationLoading: false,
          locationPermissionDenied: true,
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      );

      state = state.copyWith(
        userLat: pos.latitude,
        userLng: pos.longitude,
        radius: state.radius ?? 5.0,
        locationLoading: false,
        sortBy: 'distance',
      );

      // Reload with geo context
      await search(refresh: true);
    } catch (_) {
      state = state.copyWith(
          locationLoading: false, locationPermissionDenied: true);
    }
  }

  void clearLocation() {
    state = state.copyWith(
      userLat: null,
      userLng: null,
      radius: null,
      sortBy: 'relevance',
    );
  }

  // ── Filters ─────────────────────────────────────────────────────────────

  void setQuery(String? q) {
    state = state.copyWith(query: q, page: 1, hasMore: true, results: []);
  }

  void applyFilters({
    Object? category = _sentinel,
    Object? minPrice = _sentinel,
    Object? maxPrice = _sentinel,
    Object? minRating = _sentinel,
    Object? isOpenNow = _sentinel,
    String? sortBy,
    String? sortOrder,
    Object? radius = _sentinel,
  }) {
    state = state.copyWith(
      category: category,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minRating: minRating,
      isOpenNow: isOpenNow,
      sortBy: sortBy,
      sortOrder: sortOrder,
      radius: radius,
      page: 1,
      hasMore: true,
      results: [],
    );
  }

  void clearFilters() {
    state = state.copyWith(
      category: null,
      minPrice: null,
      maxPrice: null,
      minRating: null,
      isOpenNow: null,
      sortBy: 'relevance',
      sortOrder: 'asc',
      radius: state.userLat != null ? 5.0 : null,
      page: 1,
      hasMore: true,
      results: [],
    );
  }

  // ── Search ───────────────────────────────────────────────────────────────

  Future<void> search({bool refresh = false}) async {
    if (!refresh &&
        (state.isLoading || state.isLoadingMore || !state.hasMore)) {
      return;
    }

    // Cache TTL: skip network call if results are fresh
    if (!refresh &&
        state.cachedAt != null &&
        DateTime.now().difference(state.cachedAt!) < _cacheTtl &&
        state.results.isNotEmpty) {
      return;
    }

    final page = refresh ? 1 : state.page;
    if (refresh) {
      state =
          state.copyWith(isLoading: true, error: null, page: 1, hasMore: true);
    } else {
      state = state.copyWith(isLoadingMore: true, error: null);
    }

    try {
      final data = await _datasource.search(
        query: state.query,
        category: state.category,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
        minRating: state.minRating,
        lat: state.userLat,
        lng: state.userLng,
        radius: state.radius,
        isOpenNow: state.isOpenNow,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
        page: page,
      );

      final items = (data['items'] as List)
          .map((e) =>
              RestaurantSearchResultModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final totalPages = data['totalPages'] as int? ?? 1;
      final hasMore = page < totalPages;

      final merged = refresh ? items : [...state.results, ...items];
      state = state.copyWith(
        results: merged,
        isLoading: false,
        isLoadingMore: false,
        page: page + 1,
        hasMore: hasMore,
        cachedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Erro ao buscar restaurantes.',
      );
    }
  }
}
