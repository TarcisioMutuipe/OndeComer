import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/review_viewmodel.dart';

/// Tela de moderação para o dono do restaurante.
/// Exibe avaliações e comentários pendentes; permite aprovar ou rejeitar.
class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moderationViewModelProvider);
    final vm = ref.read(moderationViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderação'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.load,
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: vm.load,
              child: CustomScrollView(
                slivers: [
                  if (state.error != null)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(state.error!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ),

                  // ── Pending Ratings ────────────────────────────────────
                  _SectionHeader(
                    title: 'Avaliações pendentes',
                    count: state.pendingReviews.length,
                  ),
                  if (state.pendingReviews.isEmpty)
                    const SliverToBoxAdapter(
                      child: _EmptyState(message: 'Nenhuma avaliação pendente'),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final r = state.pendingReviews[i];
                          return _ModerationCard(
                            title: '${r.rating} ★  —  ${r.userName}',
                            subtitle: _formatDate(r.createdAt),
                            onApprove: () => vm.moderateReview(r.id, 'approve'),
                            onReject: () => vm.moderateReview(r.id, 'reject'),
                          );
                        },
                        childCount: state.pendingReviews.length,
                      ),
                    ),

                  // ── Pending Comments ───────────────────────────────────
                  _SectionHeader(
                    title: 'Comentários pendentes',
                    count: state.pendingComments.length,
                  ),
                  if (state.pendingComments.isEmpty)
                    const SliverToBoxAdapter(
                      child: _EmptyState(message: 'Nenhum comentário pendente'),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final c = state.pendingComments[i];
                          return _ModerationCard(
                            title: c.userName,
                            subtitle: c.text,
                            badge: c.dishName,
                            createdAt: _formatDate(c.createdAt),
                            onApprove: () =>
                                vm.moderateComment(c.id, 'approve'),
                            onReject: () => vm.moderateComment(c.id, 'reject'),
                          );
                        },
                        childCount: state.pendingComments.length,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Row(
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$count',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(message, style: TextStyle(color: Colors.grey.shade600)),
    );
  }
}

class _ModerationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final String? createdAt;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ModerationCard({
    required this.title,
    required this.subtitle,
    this.badge,
    this.createdAt,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badge!,
                    style:
                        TextStyle(fontSize: 11, color: Colors.blue.shade700)),
              ),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 13)),
            if (createdAt != null)
              Text(createdAt!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  label: const Text('Rejeitar',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Aprovar'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
