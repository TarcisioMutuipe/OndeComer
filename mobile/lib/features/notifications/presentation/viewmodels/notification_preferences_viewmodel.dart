import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/models/notification_preference_model.dart';

final notificationPreferencesViewModelProvider = StateNotifierProvider<
    NotificationPreferencesViewModel,
    AsyncValue<NotificationPreference>>((ref) {
  return NotificationPreferencesViewModel(
    ref.watch(notificationDatasourceProvider),
  );
});

class NotificationPreferencesViewModel
    extends StateNotifier<AsyncValue<NotificationPreference>> {
  final NotificationRemoteDatasource _datasource;

  NotificationPreferencesViewModel(this._datasource)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await _datasource.getPreferences();
      state = AsyncValue.data(prefs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleNewComment(bool value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _update(current.copyWith(newComment: value));
  }

  Future<void> toggleNewReview(bool value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _update(current.copyWith(newReview: value));
  }

  Future<void> togglePromotionActive(bool value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _update(current.copyWith(promotionActive: value));
  }

  Future<void> toggleNewDish(bool value) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _update(current.copyWith(newDish: value));
  }

  Future<void> _update(NotificationPreference prefs) async {
    try {
      final updated = await _datasource.updatePreferences(prefs);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
