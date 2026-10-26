import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/feed_remote_datasource.dart';

final finalizePromotionTicketViewModelProvider = StateNotifierProvider<
    FinalizePromotionTicketViewModel, AsyncValue<Map<String, dynamic>?>>((ref) {
  return FinalizePromotionTicketViewModel(
      ref.watch(feedRemoteDatasourceProvider));
});

class FinalizePromotionTicketViewModel
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final FeedRemoteDatasource _datasource;

  FinalizePromotionTicketViewModel(this._datasource)
      : super(const AsyncValue.data(null));

  Future<void> finalize(String qrCodeToken) async {
    state = const AsyncValue.loading();
    try {
      final result = await _datasource.finalizePromotionTicket(qrCodeToken);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}
