import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/dashboard_metrics_viewmodel.dart';
import '../viewmodels/restaurant_viewmodel.dart';
import '../../data/models/dashboard_overview_model.dart';
import '../../data/models/dish_metric_model.dart';
import '../../data/models/hour_metric_model.dart';
import '../../data/models/comment_metric_model.dart';
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
    final id = _restaurantId;

    if (id == null) {
      return MainScaffold(
        child: Scaffold(
          appBar: AppBar(title: const Text('Painel')),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MainScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel'),
          actions: [
            IconButton(
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
        ...dishes.take(10).map((dish) => _dishBar(dish, dishes)),
      ],
    );
  }

  Widget _dishBar(DishMetric dish, List<DishMetric> all) {
    final maxReviews =
        all.map((d) => d.reviewCount).fold(1, (a, b) => a > b ? a : b);
    final progress = maxReviews > 0 ? dish.reviewCount / maxReviews : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dish.dishName,
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
        Text('Horários de Pico', style: Theme.of(context).textTheme.titleLarge),
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

              return Expanded(
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
                          color: isHighlight
                              ? Colors.orange
                              : Colors.orange.shade200,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        h.hour % 3 == 0 ? '${h.hour}h' : '',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
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
}
