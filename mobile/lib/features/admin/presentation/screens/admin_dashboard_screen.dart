import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../../data/models/admin_models.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel Admin'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
              Tab(text: 'Usuários', icon: Icon(Icons.people)),
              Tab(text: 'Moderação', icon: Icon(Icons.shield)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DashboardTab(),
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
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (dashboard) {
        if (dashboard == null) return const SizedBox.shrink();
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(adminDashboardViewModelProvider.notifier).load(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Visão Geral',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              _buildGrid(context, dashboard),
              const SizedBox(height: 24),
              Text('Atividade', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _infoCard(
                  'Novos hoje', dashboard.usersToday.toString(), Icons.today),
              _infoCard('Novos esta semana', dashboard.usersThisWeek.toString(),
                  Icons.date_range),
              _infoCard('Moderações pendentes',
                  dashboard.pendingModerations.toString(), Icons.pending),
              _infoCard('Campanhas ativas',
                  dashboard.activeCampaigns.toString(), Icons.campaign),
            ],
          ),
        );
      },
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

  Widget _infoCard(String label, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
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
