import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../feed/data/datasources/feed_remote_datasource.dart';
import '../../../feed/data/models/city_event_model.dart';
import '../../../feed/presentation/viewmodels/feed_viewmodel.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../../data/models/admin_models.dart';
import 'admin_restaurant_list_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel Admin'),
          actions: [
            IconButton(
              tooltip: 'Sair',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Sair'),
                    content: const Text('Deseja sair da sua conta?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Sair'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authViewModelProvider.notifier).logout();
                  if (context.mounted) context.go(AppRoutes.login);
                }
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
              Tab(text: 'Eventos & Notícias', icon: Icon(Icons.campaign)),
              Tab(text: 'Restaurantes', icon: Icon(Icons.restaurant)),
              Tab(text: 'Usuários', icon: Icon(Icons.people)),
              Tab(text: 'Moderação', icon: Icon(Icons.shield)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DashboardTab(),
            _EventsTab(),
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

              // Reservas & Eventos da Cidade
              Text('Reservas & Eventos da Cidade',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _userStatColumn(context, 'Reservas Totais', dashboard.totalReservations, Icons.table_restaurant, Colors.teal),
                      _userStatColumn(context, 'Confirmadas', dashboard.confirmedReservations, Icons.check_circle_outline, Colors.green),
                      _userStatColumn(context, 'Pendentes', dashboard.pendingReservations, Icons.pending_actions, Colors.orange),
                      _userStatColumn(context, 'Eventos', dashboard.totalEvents, Icons.campaign, Colors.purple),
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

class _RestaurantsTab extends StatelessWidget {
  const _RestaurantsTab();

  @override
  Widget build(BuildContext context) {
    return const AdminRestaurantListScreen(isEmbedded: true);
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

class _EventsTab extends ConsumerStatefulWidget {
  const _EventsTab();

  @override
  ConsumerState<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends ConsumerState<_EventsTab> {
  bool _isLoading = true;
  String? _error;
  List<CityEventModel> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await ref.read(feedRemoteDatasourceProvider).getEvents();
      if (mounted) {
        setState(() {
          _events = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteEvent(CityEventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Evento?'),
        content: Text('Deseja remover "${event.title}" do feed de eventos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(feedRemoteDatasourceProvider).deleteEvent(event.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento removido com sucesso.'), backgroundColor: Colors.green),
        );
        _loadEvents();
        ref.read(feedViewModelProvider.notifier).load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir evento: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openCreateEventDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _CreateEventDialog(),
    );
    if (created == true) {
      _loadEvents();
      ref.read(feedViewModelProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Erro ao carregar eventos: $_error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadEvents,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateEventDialog,
        icon: const Icon(Icons.add),
        label: const Text('Novo Evento / Notícia'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: _events.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('Nenhum evento ou notícia cadastrado',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                        'Publique inaugurações, festivais e acontecimentos gastronômicos na cidade.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _openCreateEventDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Criar Primeiro Evento'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final ev = _events[i];
                  return Card(
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ev.imageUrl.isNotEmpty)
                          Image.network(
                            ev.imageUrl,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 140,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      ev.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    tooltip: 'Excluir Evento',
                                    onPressed: () => _deleteEvent(ev),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ev.description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (ev.eventDate != null)
                                    Chip(
                                      avatar: const Icon(Icons.calendar_today, size: 14),
                                      label: Text(
                                        DateFormat('dd/MM/yyyy').format(ev.eventDate!),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  if (ev.locationOrAddress != null && ev.locationOrAddress!.isNotEmpty)
                                    Chip(
                                      avatar: const Icon(Icons.location_on, size: 14),
                                      label: Text(
                                        ev.locationOrAddress!,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  if (ev.youTubeVideoUrl != null && ev.youTubeVideoUrl!.isNotEmpty)
                                    Chip(
                                      avatar: const Icon(Icons.play_circle_fill, color: Colors.red, size: 14),
                                      label: const Text('Vídeo YouTube', style: TextStyle(fontSize: 11)),
                                    ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text('${ev.likesCount} curtidas', style: const TextStyle(fontSize: 12)),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.thumb_down_alt_outlined, size: 16, color: Colors.redAccent),
                                  const SizedBox(width: 4),
                                  Text('${ev.dislikesCount} não curtidas', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _CreateEventDialog extends ConsumerStatefulWidget {
  const _CreateEventDialog();

  @override
  ConsumerState<_CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends ConsumerState<_CreateEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _imgController = TextEditingController();
  final _ytController = TextEditingController();
  final _locController = TextEditingController();
  DateTime? _eventDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _imgController.dispose();
    _ytController.dispose();
    _locController.dispose();
    super.dispose();
  }

  Future<void> _pickEventDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(feedRemoteDatasourceProvider).createEvent(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        imageUrl: _imgController.text.trim(),
        youTubeVideoUrl: _ytController.text.trim().isEmpty ? null : _ytController.text.trim(),
        eventDate: _eventDate,
        locationOrAddress: _locController.text.trim().isEmpty ? null : _locController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento publicado no Feed com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar evento: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.campaign, color: Colors.purple, size: 28),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Publicar Evento ou Notícia',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título do Evento / Notícia *',
                      hintText: 'Ex: Inauguração do Restaurante Pelourinho',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o título' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição Detalhada *',
                      hintText: 'Conte o que vai rolar, cardápio especial, horários...',
                    ),
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a descrição' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _imgController,
                    decoration: const InputDecoration(
                      labelText: 'URL da Imagem de Divulgação *',
                      hintText: 'https://exemplo.com/imagem.jpg',
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o link da imagem' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ytController,
                    decoration: const InputDecoration(
                      labelText: 'Link de Vídeo no YouTube (Opcional)',
                      hintText: 'https://youtube.com/watch?v=... ou shorts',
                      prefixIcon: Icon(Icons.play_circle_outline, color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickEventDate,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data do Acontecimento (Opcional)',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _eventDate != null
                            ? DateFormat('dd/MM/yyyy').format(_eventDate!)
                            : 'Nenhuma data selecionada (Toque para definir)',
                        style: TextStyle(
                          color: _eventDate != null ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locController,
                    decoration: const InputDecoration(
                      labelText: 'Localização / Endereço (Opcional)',
                      hintText: 'Ex: Rio Vermelho, Salvador - BA',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Publicar no Feed'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
