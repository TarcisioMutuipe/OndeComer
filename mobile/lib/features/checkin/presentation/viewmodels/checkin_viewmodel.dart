import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/checkin_remote_datasource.dart';
import '../../data/models/checkin_model.dart';

// Check-in action state
final checkInActionProvider =
    StateNotifierProvider<CheckInActionViewModel, AsyncValue<CheckInModel?>>(
        (ref) {
  return CheckInActionViewModel(ref.watch(checkInDatasourceProvider));
});

class CheckInActionViewModel extends StateNotifier<AsyncValue<CheckInModel?>> {
  final CheckInRemoteDatasource _datasource;

  CheckInActionViewModel(this._datasource) : super(const AsyncValue.data(null));

  Future<void> doCheckIn({
    required String restaurantId,
    required double latitude,
    required double longitude,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _datasource.doCheckIn(
        restaurantId: restaurantId,
        latitude: latitude,
        longitude: longitude,
      );
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

// Check-in history
final checkInHistoryProvider = StateNotifierProvider<CheckInHistoryViewModel,
    AsyncValue<CheckInHistoryModel?>>((ref) {
  return CheckInHistoryViewModel(ref.watch(checkInDatasourceProvider));
});

class CheckInHistoryViewModel
    extends StateNotifier<AsyncValue<CheckInHistoryModel?>> {
  final CheckInRemoteDatasource _datasource;

  CheckInHistoryViewModel(this._datasource)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({int page = 1}) async {
    state = const AsyncValue.loading();
    try {
      final result = await _datasource.getHistory(page: page);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// QR code data
final qrCodeProvider =
    FutureProvider.family<QrCodeModel, String>((ref, restaurantId) async {
  final datasource = ref.watch(checkInDatasourceProvider);
  return datasource.getQrData(restaurantId);
});
