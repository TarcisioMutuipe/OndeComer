import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/review_datasource.dart';
import '../../data/models/comment_model.dart';
import '../../data/models/review_model.dart';
import '../../../../core/network/dio_client.dart' show friendlyErrorMessage;

// ─── State ────────────────────────────────────────────────────────────────────

class DishReviewState {
  final List<CommentModel> comments;
  final List<ReviewModel> reviews;
  final bool isLoading;
  final String? error;
  final bool submitted; // true after user submits

  const DishReviewState({
    this.comments = const [],
    this.reviews = const [],
    this.isLoading = false,
    this.error,
    this.submitted = false,
  });

  DishReviewState copyWith({
    List<CommentModel>? comments,
    List<ReviewModel>? reviews,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? submitted,
  }) =>
      DishReviewState(
        comments: comments ?? this.comments,
        reviews: reviews ?? this.reviews,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        submitted: submitted ?? this.submitted,
      );
}

// ─── ViewModel ────────────────────────────────────────────────────────────────

class DishReviewViewModel extends StateNotifier<DishReviewState> {
  final ReviewDatasource _ds;
  final String dishId;

  DishReviewViewModel(this._ds, this.dishId) : super(const DishReviewState()) {
    loadComments();
  }

  Future<void> loadComments() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final comments = await _ds.getApprovedComments(dishId);
      state = state.copyWith(comments: comments, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: friendlyErrorMessage(e));
    }
  }

  Future<bool> submitReview(int rating) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _ds.submitReview(dishId, rating);
      state = state.copyWith(isLoading: false, submitted: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  Future<bool> submitComment(String text) async {
    if (text.trim().isEmpty) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _ds.submitComment(dishId, text);
      state = state.copyWith(isLoading: false, submitted: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  static String _extractError(Object e) {
    final s = e.toString();
    if (s.contains('409') || s.contains('Conflict'))
      return 'Você já avaliou este prato.';
    if (s.contains('404')) return 'Prato não encontrado.';
    return 'Erro: $s';
  }
}

final dishReviewViewModelProvider =
    StateNotifierProvider.family<DishReviewViewModel, DishReviewState, String>(
  (ref, dishId) =>
      DishReviewViewModel(ref.watch(reviewDatasourceProvider), dishId),
);

// ─── Moderation ViewModel ─────────────────────────────────────────────────────

class ModerationState {
  final List<CommentModel> pendingComments;
  final List<ReviewModel> pendingReviews;
  final bool isLoading;
  final String? error;

  const ModerationState({
    this.pendingComments = const [],
    this.pendingReviews = const [],
    this.isLoading = false,
    this.error,
  });

  ModerationState copyWith({
    List<CommentModel>? pendingComments,
    List<ReviewModel>? pendingReviews,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      ModerationState(
        pendingComments: pendingComments ?? this.pendingComments,
        pendingReviews: pendingReviews ?? this.pendingReviews,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class ModerationViewModel extends StateNotifier<ModerationState> {
  final ReviewDatasource _ds;

  ModerationViewModel(this._ds) : super(const ModerationState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final comments = await _ds.getPendingComments();
      final reviews = await _ds.getPendingReviews();
      state = state.copyWith(
          pendingComments: comments, pendingReviews: reviews, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: friendlyErrorMessage(e));
    }
  }

  Future<void> moderateComment(String commentId, String action) async {
    try {
      await _ds.moderateComment(commentId, action);
      final updated =
          state.pendingComments.where((c) => c.id != commentId).toList();
      state = state.copyWith(pendingComments: updated);
    } catch (e) {
      state = state.copyWith(error: friendlyErrorMessage(e));
    }
  }

  Future<void> moderateReview(String reviewId, String action) async {
    try {
      await _ds.moderateReview(reviewId, action);
      final updated =
          state.pendingReviews.where((r) => r.id != reviewId).toList();
      state = state.copyWith(pendingReviews: updated);
    } catch (e) {
      state = state.copyWith(error: friendlyErrorMessage(e));
    }
  }
}

final moderationViewModelProvider =
    StateNotifierProvider<ModerationViewModel, ModerationState>(
  (ref) => ModerationViewModel(ref.watch(reviewDatasourceProvider)),
);
