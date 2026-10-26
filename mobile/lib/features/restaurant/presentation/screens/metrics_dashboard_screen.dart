import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/dashboard_metrics_viewmodel.dart';
import '../viewmodels/restaurant_viewmodel.dart';
import '../../data/models/dashboard_overview_model.dart';
import '../../data/models/dish_metric_model.dart';
import '../../data/models/hour_metric_model.dart';
import '../../data/models/comment_metric_model.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';

class MetricsDashboardScreen extends ConsumerStatefulWidget {
  final String? restaurantId;

  const MetricsDashboardScreen({super.key, this.restaurantId});

  @override
  ConsumerState<MetricsDashboardScreen> createState() =>
      _MetricsDashboardScreenState();
}

class _MetricsDashboardScreenState
    extends ConsumerState<MetricsDashboardScreen> {
  String? _restaurantId;
  int? _selectedHour;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMetrics();
    });
  }

  Future<void> _loadMetrics() async {
    var id = widget.restaurantId;
    if (id == null) {
      await ref.read(restaurantViewModelProvider.notifier).loadMyRestaurant();
      id = ref.read(restaurantViewModelProvider).restaurant?.id;
    }
    if (id != null) {
      setState(() => _restaurantId = id);
      final notifier = ref.read(dashboardMetricsProvider.notifier);
      notifier.loadAll(id);
      notifier.startPeriodicRefresh(id);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardMetricsProvider);
    final restState = ref.watch(restaurantViewModelProvider);
    final id = _restaurantId ?? restState.restaurant?.id;

    if (id == null) {
      if (restState.isLoading) {
        return MainScaffold(
          child: Scaffold(
            appBar: AppBar(title: const Text('Painel do Estabelecimento')),
            body: const Center(child: CircularProgressIndicator()),
          ),
        );
      }
      return MainScaffold(
        child: Scaffold(
          appBar: AppBar(title: const Text('Painel do Estabelecimento')),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryYellow.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.storefront_outlined,
                          size: 48,
                          color: AppTheme.primaryYellowDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Cadastre seu Estabelecimento',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Para acompanhar métricas em tempo real, validar cupons QR e gerenciar seu cardápio, complete o cadastro do seu restaurante.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppTheme.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_business),
                          label: const Text('Cadastrar Meu Restaurante'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryYellow,
                            foregroundColor: AppTheme.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () =>
                              context.push(AppRoutes.restaurantForm),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MainScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel do Estabelecimento'),
          actions: [
            IconButton(
              tooltip: 'Validar Ticket QR',
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () =>
                  context.push(AppRoutes.finalizePromotionTicket),
            ),
            IconButton(
              tooltip: 'Atualizar dados',
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  ref.read(dashboardMetricsProvider.notifier).loadAll(id),
            ),
          ],
        ),
        body: state.isLoading && state.overview == null
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && state.overview == null
                ? _buildErrorState(state.error!, id)
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(dashboardMetricsProvider.notifier).loadAll(id),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildQuickActions(context, id),
                        const SizedBox(height: 20),
                        if (state.overview != null)
                          _buildOverviewCards(state.overview!),
                        const SizedBox(height: 24),
                        if (state.dishMetrics.isNotEmpty)
                          _buildDishRankingSection(state.dishMetrics)
                        else
                          _buildEmptySection(
                              'Nenhuma avaliação de prato ainda'),
                        const SizedBox(height: 24),
                        if (state.hourMetrics.isNotEmpty)
                          _buildHourChart(state.hourMetrics)
                        else
                          _buildEmptySection('Sem dados de horário'),
                        const SizedBox(height: 24),
                        if (state.commentMetrics != null)
                          _buildCommentSection(state.commentMetrics!),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState(String error, String restaurantId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Erro ao carregar métricas',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref
                .read(dashboardMetricsProvider.notifier)
                .loadAll(restaurantId),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(DashboardOverview overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Visão Geral', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _metricCard(
              'Pratos Ativos',
              '${overview.activeDishes}/${overview.totalDishes}',
              Icons.restaurant_menu,
              Colors.orange,
            ),
            _metricCard(
              'Nota Média',
              overview.averageRating.toStringAsFixed(1),
              Icons.star,
              Colors.amber,
            ),
            _metricCard(
              'Avaliações',
              '${overview.totalReviews}',
              Icons.rate_review,
              Colors.blue,
            ),
            _metricCard(
              'Taxa Aprovação',
              '${overview.approvalRate.toStringAsFixed(0)}%',
              Icons.check_circle,
              Colors.green,
            ),
            _metricCard(
              'Pendentes',
              '${overview.pendingReviews + overview.pendingComments}',
              Icons.pending_actions,
              Colors.deepOrange,
            ),
            _metricCard(
              'Comentários',
              '${overview.totalComments}',
              Icons.comment,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDishRankingSection(List<DishMetric> dishes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ranking de Pratos',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...dishes.take(10).toList().asMap().entries.map((e) => _dishBar(e.value, dishes, e.key)),
      ],
    );
  }

  Widget _dishBar(DishMetric dish, List<DishMetric> all, int index) {
    final maxReviews =
        all.map((d) => d.reviewCount).fold(1, (a, b) => a > b ? a : b);
    final progress = maxReviews > 0 ? dish.reviewCount / maxReviews : 0.0;

    final badge = switch (index) {
      0 => '🥇',
      1 => '🥈',
      2 => '🥉',
      _ => '#${index + 1}',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$badge ${dish.dishName}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: dish.isActive ? null : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  Text(' ${dish.averageRating.toStringAsFixed(1)}'),
                  const SizedBox(width: 8),
                  Text('(${dish.reviewCount})',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                dish.isActive ? Colors.orange : Colors.grey,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourChart(List<HourMetric> hours) {
    final maxInteractions =
        hours.map((h) => h.totalInteractions).fold(1, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Horários de Pico', style: Theme.of(context).textTheme.titleLarge),
            Text('Toque para detalhar',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: hours.map((h) {
              final height = maxInteractions > 0
                  ? (h.totalInteractions / maxInteractions) * 130
                  : 0.0;
              final isHighlight =
                  h.totalInteractions == maxInteractions && maxInteractions > 0;
              final isSelected = _selectedHour == h.hour;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() {
                    _selectedHour = _selectedHour == h.hour ? null : h.hour;
                  }),
                  child: Tooltip(
                  message:
                      '${h.hour}h: ${h.totalInteractions} interações\n(${h.reviewCount} avaliações, ${h.commentCount} comentários)',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isHighlight)
                        Text(
                          '${h.totalInteractions}',
                          style: const TextStyle(
                              fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      Container(
                        height: height,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.deepOrange
                              : (isHighlight
                                  ? Colors.orange
                                  : Colors.orange.shade200),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        h.hour % 3 == 0 ? '${h.hour}h' : '',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.deepOrange : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      if (_selectedHour != null) ...[
        const SizedBox(height: 12),
        Builder(builder: (context) {
          final sel = hours.firstWhere(
            (h) => h.hour == _selectedHour,
            orElse: () => hours.first,
          );
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.shade400,
                  foregroundColor: Colors.white,
                  child: Text('${sel.hour}h',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${sel.totalInteractions} interações às ${sel.hour}:00',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${sel.reviewCount} avaliações • ${sel.commentCount} comentários',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _selectedHour = null),
                ),
              ],
            ),
          );
        }),
      ],
    ],
  );
  }

  Widget _buildCommentSection(CommentMetric metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comentários', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            _commentChip('Aprovados', metrics.approvedComments, Colors.green),
            const SizedBox(width: 8),
            _commentChip('Pendentes', metrics.pendingComments, Colors.orange),
            const SizedBox(width: 8),
            _commentChip('Rejeitados', metrics.rejectedComments, Colors.red),
          ],
        ),
        const SizedBox(height: 16),
        if (metrics.recentComments.isNotEmpty) ...[
          Text('Últimos Comentários',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...metrics.recentComments.take(5).map(_commentTile),
        ] else
          _buildEmptySection('Nenhum comentário recebido'),
      ],
    );
  }

  Widget _commentChip(String label, int count, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text('$count',
            style: const TextStyle(color: Colors.white, fontSize: 11)),
      ),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _commentTile(RecentComment comment) {
    final statusColor = switch (comment.status) {
      'Approved' => Colors.green,
      'Pending' => Colors.orange,
      'Rejected' => Colors.red,
      _ => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 6,
          backgroundColor: statusColor,
        ),
        title: Text(comment.text, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${comment.userName} • ${comment.dishName}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.analytics_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, String id) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ações Rápidas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.menu_book, size: 16),
              label: const Text('Cardápio', style: TextStyle(fontSize: 13)),
              onPressed: () => context.push(AppRoutes.restaurantDashboard),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.qr_code_scanner,
                color: Colors.green.shade700,
                bgColor: Colors.green.shade50,
                title: 'Validar Ticket',
                subtitle: 'Escanear QR de cliente',
                onTap: () => context.push(AppRoutes.finalizePromotionTicket),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.local_offer_outlined,
                color: Colors.orange.shade800,
                bgColor: Colors.orange.shade50,
                title: 'Promoções',
                subtitle: 'Ofertas & Descontos',
                onTap: () => context.push(AppRoutes.ownerPromotions, extra: id),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.restaurant_menu,
                color: Colors.blue.shade700,
                bgColor: Colors.blue.shade50,
                title: 'Editar Pratos',
                subtitle: 'Preços & Cardápio',
                onTap: () => context.push(AppRoutes.restaurantDashboard),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.qr_code_2,
                color: Colors.purple.shade700,
                bgColor: Colors.purple.shade50,
                title: 'Kit de Mesas (A6)',
                subtitle: 'Plaquinhas do salão',
                onTap: () => context.push('/restaurant/$id/qr'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
