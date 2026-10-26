import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/youtube_video_player.dart';
import '../viewmodels/restaurant_list_viewmodel.dart';
import '../viewmodels/dish_viewmodel.dart';
import '../widgets/restaurant_open_status_badge.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Endereço copiado! Cole no Google Maps, Waze ou Uber.'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareRestaurant(dynamic restaurant) {
    final text = '🍽️ Bora conhecer o ${restaurant.name} em Salvador?\n'
        '📍 ${restaurant.address}\n'
        '⭐ Avaliação: ${restaurant.ratingAverage.toStringAsFixed(1)} estrelas\n\n'
        'Confira o cardápio e promoções no app Onde Comer em Salvador!';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Convite copiado! Cole no WhatsApp ou no grupo.'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _openWhatsAppReservation(dynamic restaurant) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final reservationMsg =
            'Olá! Vi o perfil do ${restaurant.name} no app Onde Comer em Salvador e gostaria de saber sobre reserva de mesa e atendimento para hoje. 🍽️';

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chat_outlined,
                        color: Colors.green.shade700, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Falar com ${restaurant.name}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Text(
                          'Reservas, aniversários e informações',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  reservationMsg,
                  style: const TextStyle(
                      fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar Mensagem Pronta de Reserva',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: reservationMsg));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Mensagem copiada! Cole na conversa do restaurante.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
                actions: [
                  IconButton(
                    icon: const CircleAvatar(
                      backgroundColor: Colors.white70,
                      child: Icon(Icons.share_outlined,
                          color: AppTheme.textPrimary, size: 20),
                    ),
                    onPressed: () => _shareRestaurant(restaurant),
                    tooltip: 'Compartilhar no WhatsApp ou grupo',
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: restaurant.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: restaurant.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const SkeletonLoader(height: 220, borderRadius: 0),
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
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _copyAddress(restaurant.address),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        const Icon(Icons.location_on,
                            size: 16, color: AppTheme.primaryYellowDark),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(restaurant.address,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500))),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryYellow.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy, size: 12, color: AppTheme.primaryYellowDark),
                              SizedBox(width: 4),
                              Text('Copiar GPS',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryYellowDark)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryYellow,
                          foregroundColor: AppTheme.textPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          minimumSize: const Size(0, 38),
                        ),
                        icon: const Icon(Icons.qr_code_scanner, size: 18),
                        label: const Text('Fazer Check-in & Pontuar',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: () =>
                            context.push('/checkin/${restaurant.id}'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade800,
                          side: BorderSide(color: Colors.green.shade600),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          minimumSize: const Size(0, 38),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Reservar / WhatsApp',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: () => _openWhatsAppReservation(restaurant),
                      ),
                      if (restaurant.openingHours.isNotEmpty) ...[
                        RestaurantOpenStatusBadge(
                          openingHours: restaurant.openingHours,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time,
                                  size: 15, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(restaurant.openingHours,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                      if (restaurant.instagramUrl != null &&
                          restaurant.instagramUrl!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt_outlined,
                                  size: 15, color: Colors.purple),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.instagramUrl!.contains('/')
                                    ? '@${restaurant.instagramUrl!.split('/').last}'
                                    : '@${restaurant.instagramUrl}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
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
                  memCacheWidth: 200,
                  memCacheHeight: 200,
                  placeholder: (_, __) => const SkeletonLoader(
                      width: 64, height: 64, borderRadius: 8),
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
