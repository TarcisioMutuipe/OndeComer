import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart' show friendlyErrorMessage;
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../core/router/app_router.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../../presentation/viewmodels/feed_viewmodel.dart';
import '../../data/models/promotion_model.dart';
import '../../data/models/dish_feed_post_model.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../restaurant/presentation/viewmodels/restaurant_viewmodel.dart';
import '../../../restaurant/data/models/restaurant_model.dart';

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
    final authState = ref.watch(authViewModelProvider);
    final isRestaurant = authState.user?.profileType == 'Restaurant';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: const Text('Feed Gastronômico'),
        actions: [
          if (isRestaurant) ...[
            IconButton(
              tooltip: 'Validar Ticket QR',
              icon: const Icon(Icons.qr_code_scanner, color: Colors.green),
              onPressed: () => context.push(AppRoutes.finalizePromotionTicket),
            ),
          ] else ...[
            IconButton(
              tooltip: 'Meus Tickets Resgatados',
              icon: const Icon(Icons.confirmation_number_outlined,
                  color: AppTheme.primaryYellowDark),
              onPressed: () => context.push(AppRoutes.myTickets),
            ),
          ],
          IconButton(
            tooltip: 'Atualizar feed',
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
    final authState = ref.watch(authViewModelProvider);
    final isRestaurant = authState.user?.profileType == 'Restaurant';
    final restaurant = ref.watch(restaurantViewModelProvider).restaurant;

    if (state.isLoading) {
      return ListView.builder(
          itemCount: 5, itemBuilder: (_, __) => const FeedSkeletonCard());
    }
    final isFeedEmpty = state.promotions.isEmpty && state.dishPosts.isEmpty;
    if (state.error != null && isFeedEmpty) {
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
    if (isFeedEmpty) {
      return ListView(
        children: [
          if (isRestaurant) _buildRestaurantOwnerHeader(context, restaurant),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.local_offer_outlined,
                    size: 64, color: AppTheme.divider),
                SizedBox(height: 16),
                Text('Nenhuma publicação no momento.',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                SizedBox(height: 8),
                Text(
                    'Em breve os restaurantes de Salvador\nvão publicar pratos e ofertas aqui!',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      );
    }

    final headerOffset = isRestaurant ? 1 : 0;
    final feedItems = <Object>[
      ...state.promotions,
      ...state.dishPosts
    ]..sort((first, second) => _createdAt(second).compareTo(_createdAt(first)));
    final totalCount =
        headerOffset + feedItems.length + (state.isLoadingMore ? 2 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: totalCount,
      itemBuilder: (context, i) {
        if (isRestaurant && i == 0) {
          return _buildRestaurantOwnerHeader(context, restaurant);
        }
        final itemIndex = i - headerOffset;
        if (itemIndex >= feedItems.length) return const FeedSkeletonCard();
        final item = feedItems[itemIndex];
        if (item is PromotionModel) {
          return _PromotionCard(
            promotion: item,
            onTap: () => context.push(AppRoutes.promotionDetails, extra: item),
            onClaim: () => _claimPromotion(context, item),
          );
        }
        final dish = item as DishFeedPostModel;
        return _DishPostCard(
          post: dish,
          onTap: () => context.push(_dishMenuLocation(dish)),
        );
      },
    );
  }

  DateTime _createdAt(Object item) => item is PromotionModel
      ? item.createdAt
      : (item as DishFeedPostModel).createdAt;

  String _dishMenuLocation(DishFeedPostModel post) {
    final category = _menuCategory(post.category);
    return Uri(
      path: '/restaurant/${post.restaurantId}/menu',
      queryParameters: {
        'categoria': category,
        if (post.subcategory?.trim().isNotEmpty ?? false)
          'subcategoria': post.subcategory!.trim(),
        'prato': post.id,
      },
    ).toString();
  }

  Widget _buildRestaurantOwnerHeader(
      BuildContext context, RestaurantModel? restaurant) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront,
                  color: AppTheme.primaryYellowDark, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  restaurant?.name != null
                      ? 'Painel do Restaurante • ${restaurant!.name}'
                      : 'Área do Estabelecimento',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Valide os cupons apresentados pelos clientes ou gerencie as ofertas promocionais do seu restaurante.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner, size: 16),
                  label: const Text('Validar Ticket QR',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () =>
                      context.push(AppRoutes.finalizePromotionTicket),
                ),
              ),
              if (restaurant != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.campaign_outlined, size: 16),
                    label: const Text('Minhas Ofertas',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepOrange.shade800,
                      side: BorderSide(color: Colors.deepOrange.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => context.push(AppRoutes.ownerPromotions,
                        extra: restaurant.id),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _claimPromotion(
      BuildContext context, PromotionModel promotion) async {
    try {
      final response = await ref
          .read(feedRemoteDatasourceProvider)
          .claimPromotion(promotion.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              response['message'] as String? ?? 'Ticket obtido com sucesso!'),
          action: SnackBarAction(
            label: 'Ver Meus Tickets',
            textColor: AppTheme.primaryYellow,
            onPressed: () => context.push(AppRoutes.myTickets),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(friendlyErrorMessage(e)),
      ));
    }
  }
}

class _PromotionCard extends StatelessWidget {
  final PromotionModel promotion;
  final VoidCallback onTap;
  final VoidCallback onClaim;
  const _PromotionCard(
      {required this.promotion, required this.onTap, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final canClaimNow = promotion.canClaim && promotion.remainingTickets > 0;
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
                  memCacheWidth: 600,
                  placeholder: (_, __) =>
                      const SkeletonLoader(width: double.infinity, height: 160),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  _StatusPill(
                    label: canClaimNow
                        ? '${promotion.remainingTickets} tickets restantes'
                        : promotion.remainingTickets <= 0
                            ? 'Todos os tickets já foram pegos'
                            : 'Fora da janela de retirada',
                    color: canClaimNow ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(
                    label: 'Retirada até ${_formatDate(promotion.claimEndsAt)}',
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: canClaimNow ? onClaim : null,
                  icon: const Icon(Icons.back_hand_outlined),
                  label: Text(canClaimNow ? 'Pegar ticket' : 'Indisponível'),
                ),
              ),
            ),
            if (promotion.expiresAt != null)
              _ExpirationBadge(expiresAt: promotion.expiresAt!),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
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

String _menuCategory(String category) {
  final normalized = category.trim().toLowerCase();
  if (normalized.contains('entrada')) return 'Entradas';
  if (normalized.contains('principal')) return 'Menu Principal';
  if (normalized.contains('sobremesa')) return 'Sobremesas';
  if (normalized.contains('petisco')) return 'Petiscos';
  if (normalized.contains('bebid') || normalized.contains('drink')) {
    return 'Bebidas';
  }
  if (normalized.contains('vinho')) return 'Carta de Vinhos';
  return 'Todos';
}

class _DishPostCard extends StatelessWidget {
  final DishFeedPostModel post;
  final VoidCallback onTap;

  const _DishPostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.imageUrl;
    final subtitle = [post.category, post.subcategory]
        .where((value) => value != null && value.trim().isNotEmpty)
        .join(' · ');

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl == null || imageUrl.isEmpty
                    ? Container(
                        width: 96,
                        height: 104,
                        color: AppTheme.divider,
                        child: const Icon(Icons.restaurant, size: 32),
                      )
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 96,
                        height: 104,
                        fit: BoxFit.cover,
                        memCacheWidth: 300,
                        errorWidget: (_, __, ___) => Container(
                          width: 96,
                          height: 104,
                          color: AppTheme.divider,
                          child: const Icon(Icons.restaurant, size: 32),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      post.restaurantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (post.description?.trim().isNotEmpty ?? false) ...[
                      const SizedBox(height: 5),
                      Text(
                        post.description!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'R\$ ${post.price.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryYellowDark,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
