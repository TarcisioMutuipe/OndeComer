import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/rankings_viewmodel.dart';

class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends ConsumerState<RankingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rankingsViewModelProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rankingsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rankings & Tendências'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Top Restaurantes'),
            Tab(text: 'Top Pratos'),
            Tab(text: 'Tendências'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.error!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(rankingsViewModelProvider.notifier)
                            .loadAll(),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _TopRestaurantsTab(items: state.topRestaurants),
                    _TopDishesTab(items: state.topDishes),
                    _TrendingTab(
                      trending: state.trendingDishes,
                      promotions: state.featuredPromotions,
                    ),
                  ],
                ),
    );
  }
}

class _TopRestaurantsTab extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _TopRestaurantsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Nenhum restaurante encontrado.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final rank = index + 1;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: rank <= 3 ? Colors.orange : Colors.grey[300],
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.white : Colors.black87,
                ),
              ),
            ),
            title: Text(
              item['restaurantName'] ?? item['name'] ?? 'Restaurante',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '⭐ ${(item['averageRating'] ?? 0).toStringAsFixed(1)} • ${item['reviewCount'] ?? 0} avaliações',
            ),
            trailing: rank <= 3
                ? Icon(Icons.emoji_events, color: _medalColor(rank))
                : null,
            onTap: () {
              final id = item['restaurantId']?.toString();
              if (id != null) {
                Navigator.of(context).pushNamed('/restaurant/$id');
              }
            },
          ),
        );
      },
    );
  }

  Color _medalColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return Colors.grey;
    }
  }
}

class _TopDishesTab extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _TopDishesTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Nenhum prato encontrado.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final rank = index + 1;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: rank <= 3 ? Colors.deepOrange : Colors.grey[300],
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.white : Colors.black87,
                ),
              ),
            ),
            title: Text(
              item['dishName'] ?? item['name'] ?? 'Prato',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '⭐ ${(item['averageRating'] ?? item['ratingAverage'] ?? 0).toStringAsFixed(1)} • ${item['restaurantName'] ?? ''}',
            ),
          ),
        );
      },
    );
  }
}

class _TrendingTab extends StatelessWidget {
  final List<Map<String, dynamic>> trending;
  final List<Map<String, dynamic>> promotions;
  const _TrendingTab({required this.trending, required this.promotions});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (promotions.isNotEmpty) ...[
            Text(
              '🔥 Promoções em Destaque',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...promotions.map((promo) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.orange[50],
                  child: ListTile(
                    leading:
                        const Icon(Icons.local_offer, color: Colors.orange),
                    title: Text(promo['title'] ?? ''),
                    subtitle: Text(
                      '${promo['discountPercent'] ?? 0}% OFF • ${promo['restaurantName'] ?? ''}',
                    ),
                  ),
                )),
            const SizedBox(height: 24),
          ],
          Text(
            '📈 Pratos em Alta',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          if (trending.isEmpty)
            const Center(child: Text('Sem tendências no momento.'))
          else
            ...trending.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.trending_up, color: Colors.green),
                    title: Text(item['dishName'] ?? item['name'] ?? ''),
                    subtitle: Text(
                      '${item['recentReviewCount'] ?? item['activityCount'] ?? 0} avaliações recentes • ${item['restaurantName'] ?? ''}',
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
