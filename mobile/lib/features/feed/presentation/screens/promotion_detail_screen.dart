import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart' show friendlyErrorMessage;
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../../data/models/promotion_model.dart';

class PromotionDetailScreen extends ConsumerStatefulWidget {
  final PromotionModel promotion;

  const PromotionDetailScreen({super.key, required this.promotion});

  @override
  ConsumerState<PromotionDetailScreen> createState() =>
      _PromotionDetailScreenState();
}

class _PromotionDetailScreenState extends ConsumerState<PromotionDetailScreen> {
  bool _isClaiming = false;

  Future<void> _claim() async {
    setState(() => _isClaiming = true);
    try {
      final response = await ref
          .read(feedRemoteDatasourceProvider)
          .claimPromotion(widget.promotion.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response['message']?.toString() ?? 'Ticket obtido.')),
      );
      if (context.mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final promotion = widget.promotion;
    final canClaimNow = promotion.canClaim && promotion.remainingTickets > 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Detalhes da promoção'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (promotion.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: promotion.imageUrl!,
                height: 220,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 220,
                  color: AppTheme.divider,
                  alignment: Alignment.center,
                  child: const Icon(Icons.local_offer, size: 48),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            promotion.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            promotion.restaurantName,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          if (promotion.description != null) ...[
            const SizedBox(height: 12),
            Text(promotion.description!),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.confirmation_number_outlined,
                label:
                    '${promotion.remainingTickets}/${promotion.totalTickets} tickets',
              ),
              _InfoChip(
                icon: Icons.schedule_outlined,
                label: 'Retirada até ${_formatDateTime(promotion.claimEndsAt)}',
              ),
              _InfoChip(
                icon: Icons.timelapse_outlined,
                label: '${promotion.ticketValidityDays} dias para consumir',
              ),
              _InfoChip(
                icon: Icons.sell_outlined,
                label: promotion.scope == 'SpecificDishes'
                    ? 'Pratos selecionados'
                    : 'Todo o cardápio',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _RulesCard(
            title: 'Como funciona',
            items: [
              'Pegue seu ticket enquanto houver disponibilidade.',
              'Você tem um ticket por promoção e entra em cooldown quando estoura o limite de expirados.',
              'Leve o QR ou o token ao restaurante para finalizar o consumo.',
              'Consuma dentro do prazo para evitar expiração e bloqueio temporário.',
            ],
          ),
          if ((promotion.targetDishNames ?? []).isNotEmpty) ...[
            const SizedBox(height: 16),
            _RulesCard(
              title: 'Pratos incluídos',
              items: promotion.targetDishNames!,
            ),
          ],
          const SizedBox(height: 16),
          _RulesCard(
            title: 'Janela da promoção',
            items: [
              'Início: ${_formatDateTime(promotion.claimStartsAt)}',
              'Fim: ${_formatDateTime(promotion.claimEndsAt)}',
              if (promotion.pixKey != null && promotion.pixKey!.isNotEmpty)
                'Pix: ${promotion.pixKey}',
              if (promotion.expiresAt != null)
                'Expira em ${_formatDateTime(promotion.expiresAt!)}',
            ],
          ),
          const SizedBox(height: 20),
          if (canClaimNow)
            ElevatedButton.icon(
              onPressed: _isClaiming ? null : _claim,
              icon: _isClaiming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.back_hand_outlined),
              label: Text(_isClaiming ? 'Pegando...' : 'Pegar ticket'),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                promotion.remainingTickets <= 0
                    ? 'Todos os tickets já foram pegos.'
                    : 'A retirada está fora da janela atual.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: AppTheme.white,
    );
  }
}

class _RulesCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _RulesCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(Icons.fiber_manual_record, size: 8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
