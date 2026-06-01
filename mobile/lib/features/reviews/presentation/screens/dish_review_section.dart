import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../shared/widgets/offline_action_modal.dart';
import '../../data/models/comment_model.dart';
import '../viewmodels/review_viewmodel.dart';

/// Shown at the bottom of RestaurantDetailScreen / DishDetailScreen.
/// Consumers can rate (1-5 stars) and leave a comment.
class DishReviewSection extends ConsumerStatefulWidget {
  final String dishId;
  final String dishName;

  const DishReviewSection({
    super.key,
    required this.dishId,
    required this.dishName,
  });

  @override
  ConsumerState<DishReviewSection> createState() => _DishReviewSectionState();
}

class _DishReviewSectionState extends ConsumerState<DishReviewSection> {
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  bool _showForm = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Guard: block submission when offline
    final isOffline = ref.read(isOfflineProvider);
    if (isOffline) {
      if (mounted) {
        await showOfflineActionModal(
          context,
          preservedText: _commentController.text.trim(),
        );
      }
      return;
    }

    final vm = ref.read(dishReviewViewModelProvider(widget.dishId).notifier);
    bool ok = true;

    if (_selectedRating > 0) {
      ok = await vm.submitReview(_selectedRating);
    }
    if (ok && _commentController.text.trim().isNotEmpty) {
      ok = await vm.submitComment(_commentController.text.trim());
    }

    if (ok && mounted) {
      _commentController.clear();
      setState(() {
        _selectedRating = 0;
        _showForm = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enviado! Aguardando moderação.'),
          backgroundColor: Colors.green,
        ),
      );
      await vm.loadComments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dishReviewViewModelProvider(widget.dishId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Comentários',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _showForm = !_showForm),
              icon: Icon(_showForm ? Icons.close : Icons.rate_review),
              label: Text(_showForm ? 'Cancelar' : 'Avaliar'),
            ),
          ],
        ),

        // ── Review / Comment Form ────────────────────────────────────────
        if (_showForm) ...[
          const SizedBox(height: 8),
          _StarRatingRow(
            selected: _selectedRating,
            onSelected: (r) => setState(() => _selectedRating = r),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'Deixe um comentário (opcional)...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(state.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          ElevatedButton(
            onPressed: (state.isLoading ||
                    (_selectedRating == 0 &&
                        _commentController.text.trim().isEmpty))
                ? null
                : _submit,
            child: state.isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enviar'),
          ),
          const SizedBox(height: 12),
        ],

        const Divider(),

        // ── Approved comments list ───────────────────────────────────────
        if (state.isLoading && state.comments.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (state.comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('Nenhum comentário ainda.')),
          )
        else
          ...state.comments.map((c) => _CommentTile(comment: c)),
      ],
    );
  }
}

class _StarRatingRow extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _StarRatingRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final star = i + 1;
        return IconButton(
          icon: Icon(
            star <= selected ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
          onPressed: () => onSelected(star),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        );
      }),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            child: Text(
              comment.userName.isNotEmpty
                  ? comment.userName[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(comment.text, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  _formatDate(comment.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
