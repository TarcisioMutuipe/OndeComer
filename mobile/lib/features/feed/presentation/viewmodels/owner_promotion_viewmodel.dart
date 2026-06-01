import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../../data/models/promotion_model.dart';

// ── State ──────────────────────────────────────────────────────────────────
class OwnerPromotionState {
  final List<PromotionModel> promotions;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const OwnerPromotionState({
    this.promotions = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  OwnerPromotionState copyWith({
    List<PromotionModel>? promotions,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) =>
      OwnerPromotionState(
        promotions: promotions ?? this.promotions,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: error,
      );
}

// ── Provider ───────────────────────────────────────────────────────────────
final ownerPromotionViewModelProvider = StateNotifierProvider.family<
    OwnerPromotionViewModel, OwnerPromotionState, String>(
  (ref, restaurantId) => OwnerPromotionViewModel(
      ref.watch(feedRemoteDatasourceProvider), restaurantId),
);

// ── ViewModel ─────────────────────────────────────────────────────────────
class OwnerPromotionViewModel extends StateNotifier<OwnerPromotionState> {
  final FeedRemoteDatasource _datasource;
  final String _restaurantId;

  OwnerPromotionViewModel(this._datasource, this._restaurantId)
      : super(const OwnerPromotionState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _datasource.getByRestaurant(_restaurantId);
      state = state.copyWith(promotions: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> create({
    required String title,
    String? description,
    String? imageUrl,
    double? discountPercent,
    DateTime? expiresAt,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final newPromotion = await _datasource.createPromotion(
        title: title,
        description: description,
        imageUrl: imageUrl,
        discountPercent: discountPercent,
        expiresAt: expiresAt,
      );
      state = state.copyWith(
        isSaving: false,
        promotions: [newPromotion, ...state.promotions],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> delete(String promotionId) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _datasource.deletePromotion(promotionId);
      state = state.copyWith(
        isSaving: false,
        promotions: state.promotions.where((p) => p.id != promotionId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}
