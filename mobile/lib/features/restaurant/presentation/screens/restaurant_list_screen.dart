import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../viewmodels/restaurant_list_viewmodel.dart';
import '../widgets/restaurant_card.dart';

class RestaurantListScreen extends ConsumerStatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  ConsumerState<RestaurantListScreen> createState() =>
      _RestaurantListScreenState();
}

class _RestaurantListScreenState extends ConsumerState<RestaurantListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(restaurantListViewModelProvider.notifier).load(refresh: true);
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(restaurantListViewModelProvider.notifier).load();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restaurantListViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: Image.asset('assets/images/logo.png',
            height: 32,
            errorBuilder: (_, __, ___) => const Text('Onde Comer',
                style: TextStyle(fontWeight: FontWeight.bold))),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _SearchBar(
                onSearch: (q) => ref
                    .read(restaurantListViewModelProvider.notifier)
                    .setSearch(q)),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryYellow,
        onRefresh: () => ref
            .read(restaurantListViewModelProvider.notifier)
            .load(refresh: true),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(RestaurantListState state) {
    if (state.isLoading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) => const RestaurantSkeletonCard(),
      );
    }
    if (state.error != null && state.restaurants.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off, size: 48, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text(state.error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref
                .read(restaurantListViewModelProvider.notifier)
                .load(refresh: true),
            child: const Text('Tentar novamente'),
          ),
        ]),
      );
    }
    if (state.restaurants.isEmpty) {
      return const Center(child: Text('Nenhum restaurante encontrado.'));
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.restaurants.length + (state.isLoadingMore ? 2 : 0),
      itemBuilder: (context, i) {
        if (i >= state.restaurants.length)
          return const RestaurantSkeletonCard();
        return RestaurantCard(
          restaurant: state.restaurants[i],
          onTap: () => context.push('/restaurant/${state.restaurants[i].id}'),
        );
      },
    );
  }
}

class _SearchBar extends StatefulWidget {
  final ValueChanged<String?> onSearch;
  const _SearchBar({required this.onSearch});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onSubmitted: widget.onSearch,
      decoration: InputDecoration(
        hintText: 'Buscar restaurantes em Salvador…',
        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _ctrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _ctrl.clear();
                  widget.onSearch(null);
                  setState(() {});
                })
            : null,
        filled: true,
        fillColor: AppTheme.background,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (v) => setState(() {}),
    );
  }
}
