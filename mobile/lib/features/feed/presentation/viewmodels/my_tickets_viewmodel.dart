import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../../data/models/promotion_ticket_model.dart';
import '../../../../core/network/dio_client.dart' show friendlyErrorMessage;

final myTicketsViewModelProvider =
    StateNotifierProvider<MyTicketsViewModel, MyTicketsState>((ref) {
  return MyTicketsViewModel(ref.watch(feedRemoteDatasourceProvider));
});

class MyTicketsState {
  final List<PromotionTicketModel> tickets;
  final bool isLoading;
  final String? error;

  const MyTicketsState({
    this.tickets = const [],
    this.isLoading = false,
    this.error,
  });

  MyTicketsState copyWith({
    List<PromotionTicketModel>? tickets,
    bool? isLoading,
    String? error,
  }) {
    return MyTicketsState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MyTicketsViewModel extends StateNotifier<MyTicketsState> {
  final FeedRemoteDatasource _datasource;

  MyTicketsViewModel(this._datasource) : super(const MyTicketsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tickets = await _datasource.getMyTickets();
      state = state.copyWith(tickets: tickets, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyErrorMessage(e),
      );
    }
  }
}
