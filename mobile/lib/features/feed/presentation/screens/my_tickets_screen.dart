import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../data/models/promotion_ticket_model.dart';
import '../viewmodels/my_tickets_viewmodel.dart';

class MyTicketsScreen extends ConsumerWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myTicketsViewModelProvider);
    final activeTickets =
        state.tickets.where((ticket) => ticket.isClaimed).toList();
    final expiringSoonTickets = activeTickets
        .where((ticket) =>
            ticket.expiresAt.difference(DateTime.now().toUtc()).inHours <= 24)
        .toList();
    final redeemedTickets =
        state.tickets.where((ticket) => ticket.isRedeemed).toList();
    final expiredTickets = state.tickets
        .where((ticket) => ticket.isExpired || ticket.isCancelled)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(myTicketsViewModelProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppTheme.primaryYellow,
              onRefresh: () =>
                  ref.read(myTicketsViewModelProvider.notifier).load(),
              child: state.error != null && state.tickets.isEmpty
                  ? _EmptyTicketsState(
                      message: state.error!,
                      onRetry: () =>
                          ref.read(myTicketsViewModelProvider.notifier).load(),
                    )
                  : state.tickets.isEmpty
                      ? const _EmptyTicketsState(
                          message: 'Você ainda não pegou nenhum ticket.',
                          subtitle:
                              'Quando você pegar um ticket, ele aparece aqui com QR code e prazo de validade.',
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (expiringSoonTickets.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        Colors.orange.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                        Icons.notifications_active_outlined,
                                        color: Colors.orange),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        expiringSoonTickets.length == 1
                                            ? 'Seu ticket expira em breve. Consuma antes de perder a validade.'
                                            : 'Você tem ${expiringSoonTickets.length} tickets perto de vencer. Consuma antes de perder a validade.',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (expiringSoonTickets.isNotEmpty)
                              const SizedBox(height: 16),
                            _SummaryHeader(
                              activeCount: activeTickets.length,
                              redeemedCount: redeemedTickets.length,
                              expiredCount: expiredTickets.length,
                            ),
                            const SizedBox(height: 16),
                            _TicketSection(
                              title: 'Ativos',
                              subtitle:
                                  'Tickets prontos para uso, com QR code e prazo de consumo.',
                              tickets: activeTickets,
                              emptyLabel: 'Nenhum ticket ativo no momento.',
                            ),
                            _TicketSection(
                              title: 'Usados',
                              subtitle:
                                  'Tickets já consumidos pelo restaurante.',
                              tickets: redeemedTickets,
                              emptyLabel: 'Nenhum ticket consumido ainda.',
                            ),
                            _TicketSection(
                              title: 'Expirados',
                              subtitle:
                                  'Tickets que venceram e podem gerar cooldown se repetidos.',
                              tickets: expiredTickets,
                              emptyLabel:
                                  'Nenhum ticket expirado por enquanto.',
                            ),
                          ],
                        ),
            ),
    );
  }
}

String formatTicketStatus(String status) {
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

Color _ticketStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'redeemed':
      return Colors.green;
    case 'expired':
      return AppTheme.error;
    case 'cancelled':
      return Colors.orange;
    case 'claimed':
    default:
      return AppTheme.primaryYellowDark;
  }
}

String _ticketDateTime(DateTime dateTime) {
  final date = dateTime.toLocal();
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year;
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/$year às $hour:$minute';
}

class _SummaryHeader extends StatelessWidget {
  final int activeCount;
  final int redeemedCount;
  final int expiredCount;

  const _SummaryHeader({
    required this.activeCount,
    required this.redeemedCount,
    required this.expiredCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                label: 'Ativos', value: activeCount, color: Colors.green)),
        const SizedBox(width: 8),
        Expanded(
            child: _StatCard(
                label: 'Usados', value: redeemedCount, color: Colors.blue)),
        const SizedBox(width: 8),
        Expanded(
            child: _StatCard(
                label: 'Expirados',
                value: expiredCount,
                color: AppTheme.error)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _TicketSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<PromotionTicketModel> tickets;
  final String emptyLabel;

  const _TicketSection({
    required this.title,
    required this.subtitle,
    required this.tickets,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          if (tickets.isEmpty)
            _EmptySectionCard(label: emptyLabel)
          else
            ...tickets.map(
              (ticket) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TicketCard(ticket: ticket),
              ),
            ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final PromotionTicketModel ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _ticketStatusColor(ticket.status);
    final remaining = ticket.expiresAt.difference(DateTime.now().toUtc());
    final countdown = ticket.isClaimed
        ? _formatDuration(remaining)
        : ticket.isRedeemed
            ? 'Consumido em ${_ticketDateTime(ticket.redeemedAt ?? ticket.claimedAt)}'
            : 'Expirado';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.dividerDark : AppTheme.divider,
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                    color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.restaurantName,
                      style: TextStyle(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  formatTicketStatus(ticket.status).toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Resgatado em ${_ticketDateTime(ticket.claimedAt)}',
            style: TextStyle(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            'Válido até ${_ticketDateTime(ticket.expiresAt)}',
            style: TextStyle(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ticket.isClaimed
                ? 'Você ainda pode consumir este ticket por $countdown.'
                : ticket.isRedeemed
                    ? 'Este ticket já foi consumido.'
                    : 'Este ticket expirou e não pode mais ser usado.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
            ),
          ),
          if (ticket.discountPercent != null) ...[
            const SizedBox(height: 8),
            Text(
              'Desconto: ${ticket.discountPercent!.toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: QrImageView(
                  data: ticket.qrCodeToken,
                  size: 100,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Token do QR',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      ticket.qrCodeToken,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: ticket.qrCodeToken));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Token copiado com sucesso!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimary,
                        side: BorderSide(
                          color: isDark
                              ? AppTheme.dividerDark
                              : AppTheme.divider,
                        ),
                      ),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copiar token'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'expirado';
    if (duration.inDays > 0) return '${duration.inDays} dia(s)';
    if (duration.inHours > 0) return '${duration.inHours} hora(s)';
    return '${duration.inMinutes.clamp(1, 59)} min';
  }
}

class _EmptySectionCard extends StatelessWidget {
  final String label;

  const _EmptySectionCard({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppTheme.dividerDark : AppTheme.divider),
      ),
      child: Text(label,
          style: TextStyle(
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondary)),
    );
  }
}

class _EmptyTicketsState extends StatelessWidget {
  final String message;
  final String? subtitle;
  final VoidCallback? onRetry;

  const _EmptyTicketsState(
      {required this.message, this.subtitle, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.confirmation_number_outlined,
            size: 64, color: AppTheme.divider),
        const SizedBox(height: 16),
        Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ),
        ],
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ),
        ] else ...[
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.feed),
              icon: const Icon(Icons.local_offer_outlined),
              label: const Text('Explorar Ofertas Disponíveis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                foregroundColor: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
