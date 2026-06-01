import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../presentation/viewmodels/feed_viewmodel.dart';
import '../../data/models/promotion_model.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedViewModelProvider.notifier).load(refresh: true);
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(feedViewModelProvider.notifier).load();
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
    final state = ref.watch(feedViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: const Text('Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(feedViewModelProvider.notifier).load(refresh: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryYellow,
        onRefresh: () =>
            ref.read(feedViewModelProvider.notifier).load(refresh: true),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(FeedState state) {
    if (state.isLoading) {
      return ListView.builder(
          itemCount: 5, itemBuilder: (_, __) => const FeedSkeletonCard());
    }
    if (state.error != null && state.promotions.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off, size: 48, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          const Text('Não foi possível carregar o feed.',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () =>
                ref.read(feedViewModelProvider.notifier).load(refresh: true),
            child: const Text('Tentar novamente'),
          ),
        ]),
      );
    }
    if (state.promotions.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.local_offer_outlined,
              size: 64, color: AppTheme.divider),
          const SizedBox(height: 16),
          const Text('Nenhuma promoção no momento.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
              'Em breve os restaurantes de Salvador\nvão publicar ofertas aqui!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ]),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.promotions.length + (state.isLoadingMore ? 2 : 0),
      itemBuilder: (context, i) {
        if (i >= state.promotions.length) return const FeedSkeletonCard();
        return _PromotionCard(
          promotion: state.promotions[i],
          onTap: () =>
              context.push('/restaurant/${state.promotions[i].restaurantId}'),
        );
      },
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final PromotionModel promotion;
  final VoidCallback onTap;
  const _PromotionCard({required this.promotion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (promotion.imageUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: promotion.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(height: 160, color: AppTheme.divider),
                  errorWidget: (_, __, ___) =>
                      Container(height: 80, color: AppTheme.divider),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (promotion.restaurantLogoUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: promotion.restaurantLogoUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.restaurant, size: 44),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.restaurant,
                          color: AppTheme.primaryYellowDark),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(promotion.restaurantName,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                        Text(promotion.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        if (promotion.description != null)
                          Text(promotion.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  if (promotion.discountPercent != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                          '${promotion.discountPercent!.toStringAsFixed(0)}% OFF',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary)),
                    ),
                ],
              ),
            ),
            // ── Countdown badge ──────────────────────────────────────────
            if (promotion.expiresAt != null)
              _ExpirationBadge(expiresAt: promotion.expiresAt!),
          ],
        ),
      ),
    );
  }
}

class _ExpirationBadge extends StatelessWidget {
  final DateTime expiresAt;
  const _ExpirationBadge({required this.expiresAt});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final diff = expiresAt.toUtc().difference(now);

    if (diff.isNegative) return const SizedBox.shrink();

    final String label;
    final Color color;
    if (diff.inHours < 1) {
      label = 'Expira em ${diff.inMinutes}min';
      color = Colors.red.shade600;
    } else if (diff.inHours < 24) {
      label = 'Expira em ${diff.inHours}h';
      color = Colors.orange.shade700;
    } else {
      label = 'Expira em ${diff.inDays}d';
      color = AppTheme.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(children: [
        Icon(Icons.access_time, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ]),
    );
  }
}
