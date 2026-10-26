import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/models/promotion_ticket_admin_models.dart';

final adminPromotionTicketsProvider = StateNotifierProvider<
    AdminPromotionTicketsViewModel,
    AsyncValue<AdminPromotionTicketsState>>((ref) {
  return AdminPromotionTicketsViewModel(ref.watch(adminDatasourceProvider));
});

class AdminPromotionTicketsState {
  final PromotionTicketsSummaryModel? summary;
  final List<PromotionTicketAdminModel> tickets;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? restaurantId;
  final String? status;
  final DateTime? from;
  final DateTime? to;
  final int page;
  final int pageSize;
  final bool hasMore;

  const AdminPromotionTicketsState({
    this.summary,
    this.tickets = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.restaurantId,
    this.status,
    this.from,
    this.to,
    this.page = 1,
    this.pageSize = 20,
    this.hasMore = true,
  });

  AdminPromotionTicketsState copyWith({
    PromotionTicketsSummaryModel? summary,
    List<PromotionTicketAdminModel>? tickets,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? restaurantId,
    String? status,
    DateTime? from,
    DateTime? to,
    int? page,
    int? pageSize,
    bool? hasMore,
  }) {
    return AdminPromotionTicketsState(
      summary: summary ?? this.summary,
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      restaurantId: restaurantId ?? this.restaurantId,
      status: status ?? this.status,
      from: from ?? this.from,
      to: to ?? this.to,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class AdminPromotionTicketsViewModel
    extends StateNotifier<AsyncValue<AdminPromotionTicketsState>> {
  final AdminRemoteDatasource _datasource;

  AdminPromotionTicketsViewModel(this._datasource)
      : super(const AsyncValue.data(AdminPromotionTicketsState())) {
    load(refresh: true);
  }

  Future<void> load({bool refresh = false}) async {
    final current = state.valueOrNull ?? const AdminPromotionTicketsState();
    final nextPage = refresh ? 1 : current.page;

    state = AsyncValue.data(current.copyWith(
      isLoading: refresh,
      isLoadingMore: !refresh,
      error: null,
      page: nextPage,
      hasMore: refresh ? true : current.hasMore,
    ));

    try {
      final summary = await _datasource.getPromotionTicketsSummary(
        restaurantId: current.restaurantId,
        status: current.status,
        from: current.from,
        to: current.to,
      );
      final page = await _datasource.getPromotionTickets(
        restaurantId: current.restaurantId,
        status: current.status,
        from: current.from,
        to: current.to,
        page: nextPage,
        pageSize: current.pageSize,
      );

      final tickets =
          refresh ? page.items : [...current.tickets, ...page.items];
      state = AsyncValue.data(current.copyWith(
        summary: summary,
        tickets: tickets,
        isLoading: false,
        isLoadingMore: false,
        page: page.page + 1,
        hasMore: page.hasNextPage,
      ));
    } catch (e) {
      state = AsyncValue.data(current.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> applyFilters({
    String? restaurantId,
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    final current = state.valueOrNull ?? const AdminPromotionTicketsState();
    state = AsyncValue.data(current.copyWith(
      restaurantId: restaurantId,
      status: status,
      from: from,
      to: to,
      page: 1,
      tickets: const [],
      summary: null,
      hasMore: true,
      error: null,
    ));
    await load(refresh: true);
  }

  Future<void> clearFilters() async {
    state = const AsyncValue.data(AdminPromotionTicketsState());
    await load(refresh: true);
  }
}
