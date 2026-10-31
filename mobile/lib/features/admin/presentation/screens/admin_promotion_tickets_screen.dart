import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/admin_restaurant_datasource.dart';
import '../../presentation/viewmodels/admin_restaurant_viewmodel.dart';
import '../viewmodels/admin_promotion_tickets_viewmodel.dart';
import '../../data/models/promotion_ticket_admin_models.dart';

class AdminPromotionTicketsScreen extends ConsumerStatefulWidget {
  const AdminPromotionTicketsScreen({super.key});

  @override
  ConsumerState<AdminPromotionTicketsScreen> createState() =>
      _AdminPromotionTicketsScreenState();
}

class _AdminPromotionTicketsScreenState
    extends ConsumerState<AdminPromotionTicketsScreen> {
  String? _restaurantId;
  String? _status;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(adminRestaurantProvider.notifier).loadRestaurants());
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _to = picked);
  }

  Future<void> _applyFilters() async {
    await ref.read(adminPromotionTicketsProvider.notifier).applyFilters(
          restaurantId: _restaurantId,
          status: _status,
          from: _from,
          to: _to,
        );
  }

  Future<void> _clearFilters() async {
    setState(() {
      _restaurantId = null;
      _status = null;
      _from = null;
      _to = null;
    });
    await ref.read(adminPromotionTicketsProvider.notifier).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(adminPromotionTicketsProvider);
    final restaurantsAsync = ref.watch(adminRestaurantProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tickets de Promoção'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(adminPromotionTicketsProvider.notifier)
                .load(refresh: true),
          ),
        ],
      ),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (state) {
          return Column(
            children: [
              _FilterPanel(
                restaurantsAsync: restaurantsAsync,
                restaurantId: _restaurantId,
                status: _status,
                from: _from,
                to: _to,
                onRestaurantChanged: (value) =>
                    setState(() => _restaurantId = value),
                onStatusChanged: (value) => setState(() => _status = value),
                onFromTap: _pickFromDate,
                onToTap: _pickToDate,
                onApply: _applyFilters,
                onClear: _clearFilters,
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref
                      .read(adminPromotionTicketsProvider.notifier)
                      .load(refresh: true),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      if (state.summary != null) ...[
                        const SizedBox(height: 8),
                        _SummaryGrid(summary: state.summary!),
                        const SizedBox(height: 16),
                      ],
                      if (state.error != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(state.error!,
                              style: const TextStyle(color: AppTheme.error)),
                        ),
                      ],
                      if (state.tickets.isEmpty)
                        const _EmptyTicketsCard()
                      else
                        ...state.tickets.map((ticket) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _AdminTicketCard(ticket: ticket),
                            )),
                      if (state.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final AsyncValue<List<AdminRestaurantEntry>> restaurantsAsync;
  final String? restaurantId;
  final String? status;
  final DateTime? from;
  final DateTime? to;
  final ValueChanged<String?> onRestaurantChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const _FilterPanel({
    required this.restaurantsAsync,
    required this.restaurantId,
    required this.status,
    required this.from,
    required this.to,
    required this.onRestaurantChanged,
    required this.onStatusChanged,
    required this.onFromTap,
    required this.onToTap,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtros',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            restaurantsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erro ao carregar restaurantes: $e'),
              data: (restaurants) => DropdownButtonFormField<String?>(
                value: restaurantId,
                decoration: const InputDecoration(labelText: 'Restaurante'),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('Todos')),
                  ...restaurants.map(
                    (entry) => DropdownMenuItem<String?>(
                      value: entry.restaurant.id,
                      child: Text(entry.restaurant.name),
                    ),
                  ),
                ],
                onChanged: onRestaurantChanged,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                DropdownMenuItem<String?>(
                    value: 'Claimed', child: Text('Resgatados (Ativos)')),
                DropdownMenuItem<String?>(
                    value: 'Redeemed', child: Text('Utilizados')),
                DropdownMenuItem<String?>(
                    value: 'Expired', child: Text('Expirados')),
                DropdownMenuItem<String?>(
                    value: 'Cancelled', child: Text('Cancelados')),
              ],
              onChanged: onStatusChanged,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onFromTap,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                        from == null ? 'Data inicial' : _formatDate(from!)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onToTap,
                    icon: const Icon(Icons.date_range),
                    label: Text(to == null ? 'Data final' : _formatDate(to!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApply,
                    child: const Text('Aplicar filtros'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onClear,
                  child: const Text('Limpar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    return '$day/$month/$year';
  }
}

class _SummaryGrid extends StatelessWidget {
  final PromotionTicketsSummaryModel summary;

  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem('Total', summary.totalTickets, Colors.blue),
      _SummaryItem('Ativos', summary.activeTickets, Colors.green),
      _SummaryItem('Consumidos', summary.redeemedTickets, Colors.teal),
      _SummaryItem('Expirados', summary.expiredTickets, Colors.red),
      _SummaryItem('Expiram já', summary.expiringSoonTickets, Colors.orange),
      _SummaryItem('Cooldown', summary.usersOnCooldown, Colors.purple),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: items.map((item) => _SummaryCard(item: item)).toList(),
    );
  }
}

class _SummaryItem {
  final String label;
  final int value;
  final Color color;

  _SummaryItem(this.label, this.value, this.color);
}

class _SummaryCard extends StatelessWidget {
  final _SummaryItem item;

  const _SummaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.value.toString(),
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: item.color)),
          const SizedBox(height: 4),
          Text(item.label,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _AdminTicketCard extends StatelessWidget {
  final PromotionTicketAdminModel ticket;

  const _AdminTicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _colorForStatus(ticket.status);
    final cardBg = isDark ? AppTheme.surfaceDark : AppTheme.white;
    final textColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final subtextColor =
        isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary;
    final borderColor = isDark ? AppTheme.dividerDark : AppTheme.divider;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.promotionTitle,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ticket.restaurantName} • ${ticket.userName}',
                      style: TextStyle(color: subtextColor),
                    ),
                    Text(
                      ticket.userEmail,
                      style: TextStyle(color: subtextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(ticket.status).toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Resgatado em ${_formatDateTime(ticket.claimedAt)}',
            style: TextStyle(color: textColor),
          ),
          Text(
            'Expira em ${_formatDateTime(ticket.expiresAt)}',
            style: TextStyle(color: textColor),
          ),
          if (ticket.redeemedAt != null)
            Text(
              'Utilizado em ${_formatDateTime(ticket.redeemedAt!)}',
              style: TextStyle(color: textColor),
            ),
          if (ticket.expirationReason != null) ...[
            const SizedBox(height: 6),
            Text(
              'Motivo: ${ticket.expirationReason}',
              style: TextStyle(color: subtextColor),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Expirações do usuário: ${ticket.userExpiredTickets}',
            style: TextStyle(color: textColor),
          ),
          if (ticket.userOnCooldown && ticket.cooldownUntil != null)
            Text(
              'Cooldown até ${_formatDateTime(ticket.cooldownUntil!)}',
              style: const TextStyle(color: AppTheme.error),
            ),
          const SizedBox(height: 12),
          SelectableText(
            ticket.qrCodeToken,
            style: TextStyle(
                fontFamily: 'monospace', fontSize: 12, color: textColor),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              side: BorderSide(color: borderColor),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: ticket.qrCodeToken));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Token copiado com sucesso!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar token'),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'claimed':
        return 'Resgatado';
      case 'redeemed':
        return 'Utilizado';
      case 'expired':
        return 'Expirado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  Color _colorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'redeemed':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      case 'claimed':
        return AppTheme.primaryYellowDark;
      default:
        return Colors.blue;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year às $hour:$minute';
  }
}

class _EmptyTicketsCard extends StatelessWidget {
  const _EmptyTicketsCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: isDark ? AppTheme.dividerDark : AppTheme.divider),
      ),
      child: Text(
        'Nenhum ticket encontrado com os filtros atuais.',
        textAlign: TextAlign.center,
        style: TextStyle(
            color:
                isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary),
      ),
    );
  }
}
