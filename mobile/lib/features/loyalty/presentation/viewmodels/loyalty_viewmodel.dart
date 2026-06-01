import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/loyalty_remote_datasource.dart';
import '../../data/models/loyalty_models.dart';

final loyaltyViewModelProvider =
    StateNotifierProvider<LoyaltyViewModel, AsyncValue<LoyaltyOverviewModel?>>(
        (ref) {
  return LoyaltyViewModel(ref.watch(loyaltyDatasourceProvider));
});

class LoyaltyViewModel
    extends StateNotifier<AsyncValue<LoyaltyOverviewModel?>> {
  final LoyaltyRemoteDatasource _datasource;

  LoyaltyViewModel(this._datasource) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final data = await _datasource.getMyLoyalty();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final campaignsProvider =
    StateNotifierProvider<CampaignsViewModel, AsyncValue<List<CampaignModel>>>(
        (ref) {
  return CampaignsViewModel(ref.watch(loyaltyDatasourceProvider));
});

class CampaignsViewModel
    extends StateNotifier<AsyncValue<List<CampaignModel>>> {
  final LoyaltyRemoteDatasource _datasource;

  CampaignsViewModel(this._datasource) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({String? restaurantId}) async {
    state = const AsyncValue.loading();
    try {
      final data =
          await _datasource.getActiveCampaigns(restaurantId: restaurantId);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
