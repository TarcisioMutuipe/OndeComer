import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../../data/models/admin_models.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel Admin'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
              Tab(text: 'Restaurantes', icon: Icon(Icons.restaurant)),
              Tab(text: 'Usuários', icon: Icon(Icons.people)),
              Tab(text: 'Moderação', icon: Icon(Icons.shield)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DashboardTab(),
            _RestaurantsTab(),
            _UsersTab(),
            _ModerationTab(),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashState = ref.watch(adminDashboardViewModelProvider);

    return dashState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                'Falha ao carregar métricas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '$e',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(adminDashboardViewModelProvider.notifier).load(),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
      data: (dashboard) {
        if (dashboard == null) return const SizedBox.shrink();
        final theme = Theme.of(context);

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(adminDashboardViewModelProvider.notifier).load(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Visão Geral da Plataforma',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildGrid(context, dashboard),
              const SizedBox(height: 24),

              // Distribuição de Usuários
              Text('Distribuição de Usuários',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _userStatColumn(context, 'Clientes', dashboard.totalConsumers, Icons.person, Colors.blue),
                          _userStatColumn(context, 'Restaurantes', dashboard.totalRestaurantOwners, Icons.store, Colors.orange),
                          _userStatColumn(context, 'Admins', dashboard.totalAdmins, Icons.admin_panel_settings, Colors.purple),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('Ativos: ${dashboard.activeUsers}',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                          Text('Inativos: ${dashboard.inactiveUsers}',
                              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                          Text('Hoje: +${dashboard.usersToday}',
                              style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                          Text('Semana: +${dashboard.usersThisWeek}',
                              style: const TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Promoções & Tickets
              Text('Promoções & Cupons',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _userStatColumn(context, 'Promos Ativas', dashboard.activePromotions, Icons.local_offer, Colors.teal),
                          _userStatColumn(context, 'Emitidos', dashboard.ticketsClaimed, Icons.confirmation_number_outlined, Colors.amber),
                          _userStatColumn(context, 'Resgatados', dashboard.ticketsRedeemed, Icons.check_circle_outline, Colors.green),
                          _userStatColumn(context, 'Expirados', dashboard.ticketsExpired, Icons.highlight_off, Colors.redAccent),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => context.push(AppRoutes.adminPromotionSettings),
                            icon: const Icon(Icons.payments_outlined, size: 18),
                            label: const Text('Cobrança Pix & Aprovação'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.push(AppRoutes.adminPromotionTickets),
                            icon: const Icon(Icons.receipt_long, size: 18),
                            label: const Text('Auditoria de Tickets'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Catálogo & Feed
              Text('Catálogo & Feed',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _userStatColumn(context, 'Rest. Ativos', dashboard.activeRestaurants, Icons.restaurant, Colors.orange),
                      _userStatColumn(context, 'Rest. Inativos', dashboard.inactiveRestaurants, Icons.storefront_outlined, Colors.blueGrey),
                      _userStatColumn(context, 'Pratos no Feed', dashboard.totalDishesInFeed, Icons.dynamic_feed, Colors.indigo),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Pratos Mais Bem Avaliados
              if (dashboard.topRatedDishes.isNotEmpty) ...[
                Text('Pratos Mais Bem Avaliados',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...dashboard.topRatedDishes.map((dish) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Icon(Icons.star, color: Colors.white),
                        ),
                        title: Text(dish.dishName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${dish.restaurantName} • R\$ ${dish.price.toStringAsFixed(2)}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  dish.ratingAverage.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Text(
                              '${dish.ratingCount} avaliaç${dish.ratingCount == 1 ? 'ão' : 'ões'}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 24),
              ],

              // Restaurantes mais favoritados
              Text('Restaurantes Mais Favoritados',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (dashboard.mostFollowedRestaurants.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Ainda não há favoritos de restaurantes cadastrados.'),
                  ),
                )
              else
                ...dashboard.mostFollowedRestaurants.map((restaurant) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.favorite, color: Colors.redAccent),
                        title: Text(restaurant.restaurantName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Chip(
                          label: Text(
                            '${restaurant.favoriteCount} salvos',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          avatar: const Icon(Icons.bookmark_added, size: 16),
                        ),
                      ),
                    )),
              const SizedBox(height: 24),

              // Moderação & Campanhas
              Text('Moderação & Atividade',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _infoCard(
                'Moderações Pendentes',
                dashboard.pendingModerations.toString(),
                Icons.pending_actions,
                dashboard.pendingModerations > 0 ? Colors.orange : Colors.grey,
              ),
              _infoCard(
                'Denúncias / Flagged',
                dashboard.flaggedModerations.toString(),
                Icons.flag,
                dashboard.flaggedModerations > 0 ? Colors.red : Colors.grey,
              ),
              _infoCard(
                'Campanhas de Fidelidade Ativas',
                dashboard.activeCampaigns.toString(),
                Icons.campaign,
                Colors.teal,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _userStatColumn(BuildContext context, String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, AdminDashboardModel d) {
    final items = [
      _MetricItem('Usuários', d.totalUsers, Icons.people, Colors.blue),
      _MetricItem(
          'Restaurantes', d.totalRestaurants, Icons.restaurant, Colors.orange),
      _MetricItem('Pratos', d.totalDishes, Icons.fastfood, Colors.green),
      _MetricItem('Reviews', d.totalReviews, Icons.star, Colors.amber),
      _MetricItem('Comentários', d.totalComments, Icons.comment, Colors.purple),
      _MetricItem('Check-ins', d.totalCheckIns, Icons.location_on, Colors.red),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items
          .map((item) => Card(
                color: item.color.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: item.color, size: 28),
                      const SizedBox(height: 8),
                      Text(item.value.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(item.label,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _infoCard(String label, String value, IconData icon, [Color? iconColor]) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(label),
        trailing: Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}

class _MetricItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  _MetricItem(this.label, this.value, this.icon, this.color);
}

class _RestaurantsTab extends ConsumerWidget {
  const _RestaurantsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Gerenciar Restaurantes'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/admin/restaurants'),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Acessar'),
          ),
        ],
      ),
    );
  }
}

class _UsersTab extends ConsumerStatefulWidget {
  const _UsersTab();
  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(adminUsersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar usuário...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  ref.read(adminUsersProvider.notifier).load();
                },
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (v) =>
                ref.read(adminUsersProvider.notifier).load(search: v),
          ),
        ),
        Expanded(
          child: usersState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (users) => ListView.builder(
              itemCount: users.length,
              itemBuilder: (ctx, i) => _userTile(users[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _userTile(AdminUserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              user.isActive ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            user.isActive ? Icons.person : Icons.person_off,
            color: user.isActive ? Colors.green : Colors.red,
          ),
        ),
        title: Text(user.name),
        subtitle: Text('${user.email}\n${user.profileType}'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'toggle') {
              ref
                  .read(adminUsersProvider.notifier)
                  .toggleUser(user.id, !user.isActive);
            } else if (action == 'delete') {
              _confirmDelete(user);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'toggle',
              child: Text(user.isActive ? 'Desativar' : 'Ativar'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(AdminUserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Excluir "${user.name}"? Esta ação é irreversível.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(adminUsersProvider.notifier).deleteUser(user.id);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _ModerationTab extends ConsumerWidget {
  const _ModerationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modState = ref.watch(adminModerationProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _filterChip(ref, 'Todos', null),
              const SizedBox(width: 8),
              _filterChip(ref, 'Flagged', 'flagged'),
              const SizedBox(width: 8),
              _filterChip(ref, 'Blocked', 'blocked'),
            ],
          ),
        ),
        Expanded(
          child: modState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (logs) => ListView.builder(
              itemCount: logs.length,
              itemBuilder: (ctx, i) => _logTile(ref, logs[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(WidgetRef ref, String label, String? result) {
    return ActionChip(
      label: Text(label),
      onPressed: () =>
          ref.read(adminModerationProvider.notifier).load(result: result),
    );
  }

  Widget _logTile(WidgetRef ref, ModerationLogModel log) {
    final color = switch (log.result) {
      'blocked' => Colors.red,
      'flagged' => Colors.orange,
      _ => Colors.green,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(Icons.shield, color: color),
        ),
        title: Text(log.entityType),
        subtitle:
            Text('Score: ${(log.confidenceScore * 100).toStringAsFixed(0)}%'
                '\nResultado: ${log.result}'
                '${log.reason != null ? '\nMotivo: ${log.reason}' : ''}'),
        isThreeLine: true,
        trailing: log.result == 'flagged' && !log.reviewedByHuman
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    tooltip: 'Aprovar',
                    onPressed: () => ref
                        .read(adminModerationProvider.notifier)
                        .review(log.id, 'approved'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.block, color: Colors.red),
                    tooltip: 'Bloquear',
                    onPressed: () => ref
                        .read(adminModerationProvider.notifier)
                        .review(log.id, 'blocked'),
                  ),
                ],
              )
            : log.reviewedByHuman
                ? const Icon(Icons.verified, color: Colors.blue)
                : null,
      ),
    );
  }
}
