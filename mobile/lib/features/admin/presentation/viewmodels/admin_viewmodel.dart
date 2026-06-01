import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/models/admin_models.dart';

final adminDashboardViewModelProvider = StateNotifierProvider<
    AdminDashboardViewModel, AsyncValue<AdminDashboardModel?>>((ref) {
  return AdminDashboardViewModel(ref.watch(adminDatasourceProvider));
});

class AdminDashboardViewModel
    extends StateNotifier<AsyncValue<AdminDashboardModel?>> {
  final AdminRemoteDatasource _datasource;

  AdminDashboardViewModel(this._datasource)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final data = await _datasource.getDashboard();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminUsersProvider = StateNotifierProvider<AdminUsersViewModel,
    AsyncValue<List<AdminUserModel>>>((ref) {
  return AdminUsersViewModel(ref.watch(adminDatasourceProvider));
});

class AdminUsersViewModel
    extends StateNotifier<AsyncValue<List<AdminUserModel>>> {
  final AdminRemoteDatasource _datasource;

  AdminUsersViewModel(this._datasource) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({String? search, String? profileType}) async {
    state = const AsyncValue.loading();
    try {
      final data =
          await _datasource.getUsers(search: search, profileType: profileType);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleUser(String userId, bool isActive) async {
    await _datasource.updateUser(userId, {'isActive': isActive});
    await load();
  }

  Future<void> deleteUser(String userId) async {
    await _datasource.deleteUser(userId);
    await load();
  }
}

final adminModerationProvider = StateNotifierProvider<AdminModerationViewModel,
    AsyncValue<List<ModerationLogModel>>>((ref) {
  return AdminModerationViewModel(ref.watch(adminDatasourceProvider));
});

class AdminModerationViewModel
    extends StateNotifier<AsyncValue<List<ModerationLogModel>>> {
  final AdminRemoteDatasource _datasource;

  AdminModerationViewModel(this._datasource)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({String? result}) async {
    state = const AsyncValue.loading();
    try {
      final data = await _datasource.getModerationLogs(result: result);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> review(String logId, String decision) async {
    await _datasource.reviewModeration(logId, decision);
    await load(result: 'flagged');
  }
}
