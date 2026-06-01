import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/youtube_video_player.dart';
import '../viewmodels/restaurant_list_viewmodel.dart';
import '../viewmodels/dish_viewmodel.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(dishViewModelProvider(widget.restaurantId).notifier)
          .loadDishes(onlyAvailable: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final restaurantAsync =
        ref.watch(restaurantDetailProvider(widget.restaurantId));
    final dishState = ref.watch(dishViewModelProvider(widget.restaurantId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: restaurantAsync.when(
        loading: () => _buildSkeleton(),
        error: (e, _) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(e.toString(), textAlign: TextAlign.center),
            TextButton(
                onPressed: () =>
                    ref.refresh(restaurantDetailProvider(widget.restaurantId)),
                child: const Text('Tentar novamente')),
          ]),
        ),
        data: (restaurant) => RefreshIndicator(
          color: AppTheme.primaryYellow,
          onRefresh: () async {
            // ignore: unused_result
            ref.refresh(restaurantDetailProvider(widget.restaurantId));
            await ref
                .read(dishViewModelProvider(widget.restaurantId).notifier)
                .loadDishes(onlyAvailable: true);
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppTheme.white,
                leading: IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.white70,
                    child: Icon(Icons.arrow_back,
                        color: AppTheme.textPrimary, size: 20),
                  ),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: restaurant.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: restaurant.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppTheme.divider),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.divider,
                            child: const Icon(Icons.restaurant,
                                size: 64, color: AppTheme.textSecondary),
                          ),
                        )
                      : Container(
                          color: AppTheme.divider,
                          child: const Icon(Icons.restaurant,
                              size: 64, color: AppTheme.textSecondary),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: AppTheme.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (restaurant.logoUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: restaurant.logoUrl!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.restaurant, size: 56),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(restaurant.name,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(restaurant.category,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary)),
                            if (restaurant.description != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(restaurant.description!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(children: [
                    const Icon(Icons.location_on,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(restaurant.address,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12))),
                  ]),
                ),
              ),
              // YouTube Video Section
              if (restaurant.youTubeVideoUrl != null &&
                  restaurant.youTubeVideoUrl!.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Vídeo',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        YouTubeVideoPlayerWidget(
                            videoUrl: restaurant.youTubeVideoUrl!),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: Divider(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Cardápio',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (dishState.isLoading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                      (_, __) => const FeedSkeletonCard(),
                      childCount: 4),
                )
              else if (dishState.dishes.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: Text('Cardápio indisponível no momento.',
                            style: TextStyle(color: AppTheme.textSecondary))),
                  ),
                )
              else
                _DishSliverList(groupedDishes: _groupDishes(dishState.dishes)),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<dynamic>> _groupDishes(List dishes) {
    final map = <String, List<dynamic>>{};
    for (final d in dishes) map.putIfAbsent(d.category, () => []).add(d);
    return map;
  }

  Widget _buildSkeleton() {
    return CustomScrollView(slivers: [
      const SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          flexibleSpace:
              FlexibleSpaceBar(background: RestaurantSkeletonCard())),
      SliverList(
          delegate: SliverChildBuilderDelegate(
              (_, __) => const FeedSkeletonCard(),
              childCount: 6)),
    ]);
  }
}

class _DishSliverList extends StatelessWidget {
  final Map<String, List<dynamic>> groupedDishes;
  const _DishSliverList({required this.groupedDishes});

  @override
  Widget build(BuildContext context) {
    final categories = groupedDishes.keys.toList();
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, i) {
        if (i.isEven) {
          final cat = categories[i ~/ 2];
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(cat,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.textPrimary)),
          );
        }
        final cat = categories[i ~/ 2];
        final dishes = groupedDishes[cat]!;
        return Column(
          children:
              dishes.map<Widget>((dish) => _DishTile(dish: dish)).toList(),
        );
      }, childCount: categories.length * 2),
    );
  }
}

class _DishTile extends StatelessWidget {
  final dynamic dish;
  const _DishTile({required this.dish});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/dish/${dish.id}', extra: dish),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)],
        ),
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dish.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (dish.description != null)
                Text(dish.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text('R\$ ${(dish.price as num).toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppTheme.primaryYellowDark,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
          if (dish.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: dish.imageUrl!,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(width: 64, height: 64, color: AppTheme.divider),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.fastfood, size: 40),
                ),
              ),
            ),
        ]),
      ), // GestureDetector
    );
  }
}
