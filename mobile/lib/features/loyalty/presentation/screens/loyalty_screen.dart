import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/loyalty_models.dart';
import '../viewmodels/loyalty_viewmodel.dart';

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loyaltyState = ref.watch(loyaltyViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fidelidade'),
      ),
      body: loyaltyState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Erro: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(loyaltyViewModelProvider.notifier).load(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (loyalty) {
          if (loyalty == null) {
            return const Center(child: Text('Nenhum dado disponível'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(loyaltyViewModelProvider.notifier).load(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPointsCard(context, loyalty),
                  const SizedBox(height: 24),
                  _buildStatsRow(loyalty),
                  const SizedBox(height: 24),
                  _buildBadgesSection(context, loyalty),
                  const SizedBox(height: 24),
                  _buildRecentPointsSection(loyalty),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPointsCard(BuildContext context, LoyaltyOverviewModel loyalty) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.stars, size: 48, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            '${loyalty.totalPoints}',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'pontos',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(LoyaltyOverviewModel loyalty) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            Icons.location_on,
            '${loyalty.totalCheckIns}',
            'Check-ins',
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            Icons.star,
            '${loyalty.totalReviews}',
            'Avaliações',
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            Icons.emoji_events,
            '${loyalty.unlockedBadges.length}',
            'Badges',
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(
      BuildContext context, LoyaltyOverviewModel loyalty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Badges',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (loyalty.badges.isEmpty)
          const Text('Nenhum badge disponível ainda.',
              style: TextStyle(color: Colors.grey))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: loyalty.badges.length,
            itemBuilder: (context, index) {
              final badge = loyalty.badges[index];
              return _buildBadgeCard(context, badge, loyalty.totalPoints);
            },
          ),
      ],
    );
  }

  Widget _buildBadgeCard(
      BuildContext context, BadgeModel badge, int totalPoints) {
    final progress = badge.requiredPoints > 0
        ? (totalPoints / badge.requiredPoints).clamp(0.0, 1.0)
        : 1.0;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showBadgeDetails(context, badge, totalPoints),
      child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: badge.isUnlocked
            ? Colors.amber.withAlpha(30)
            : Colors.grey.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badge.isUnlocked ? Colors.amber : Colors.grey.shade300,
          width: badge.isUnlocked ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            badge.isUnlocked ? Icons.emoji_events : Icons.lock,
            size: 32,
            color: badge.isUnlocked ? Colors.amber : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badge.isUnlocked ? Colors.black87 : Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (!badge.isUnlocked)
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              minHeight: 4,
            ),
        ],
      ),
    ),
  );
  }

  void _showBadgeDetails(
      BuildContext context, BadgeModel badge, int totalPoints) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 36,
              backgroundColor: badge.isUnlocked
                  ? Colors.amber.shade100
                  : Colors.grey.shade200,
              child: Icon(
                badge.isUnlocked ? Icons.emoji_events : Icons.lock_outline,
                size: 40,
                color: badge.isUnlocked ? Colors.amber.shade800 : Colors.grey,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              badge.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              badge.description.isNotEmpty
                  ? badge.description
                  : 'Selo oficial de conquista gastronômica em Salvador.',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: badge.isUnlocked
                    ? Colors.green.shade50
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: badge.isUnlocked
                      ? Colors.green.shade200
                      : Colors.amber.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    badge.isUnlocked
                        ? Icons.check_circle
                        : Icons.info_outline,
                    color: badge.isUnlocked
                        ? Colors.green.shade700
                        : Colors.amber.shade800,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      badge.isUnlocked
                          ? 'Selo conquistado! Ele fica visível no seu perfil.'
                          : 'Meta: ${badge.requiredPoints} pontos necessários (você tem $totalPoints pts).',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: badge.isUnlocked
                            ? Colors.green.shade900
                            : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPointsSection(LoyaltyOverviewModel loyalty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pontos Recentes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (loyalty.recentPoints.isEmpty)
          const Text('Nenhum ponto ganho ainda.',
              style: TextStyle(color: Colors.grey))
        else
          ...loyalty.recentPoints.map((p) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withAlpha(30),
                  child: const Icon(Icons.add, color: Colors.green, size: 20),
                ),
                title: Text(_sourceLabel(p.source)),
                subtitle: p.campaignTitle != null
                    ? Text('Campanha: ${p.campaignTitle}')
                    : null,
                trailing: Text(
                  '+${p.points}',
                  style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              )),
      ],
    );
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'checkin':
        return 'Check-in';
      case 'review':
        return 'Avaliação';
      case 'comment':
        return 'Comentário';
      case 'campaign':
        return 'Campanha';
      default:
        return source;
    }
  }
}
