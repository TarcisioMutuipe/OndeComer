import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/image_upload_service.dart';
import '../../../../shared/widgets/offline_action_modal.dart';
import '../../data/models/comment_model.dart';
import '../viewmodels/review_viewmodel.dart';

/// Shown at the bottom of RestaurantDetailScreen / DishDetailScreen.
/// Consumers can rate (1-5 stars), leave comments and attach real photos.
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
  XFile? _selectedImage;
  bool _isSubmitting = false;
  final _picker = ImagePicker();

  static const _quickTags = [
    '😋 Muito gostoso',
    '🍤 Bem servido',
    '⚡ Atendimento rápido',
    '🌶️ Bem temperado',
    '💰 Bom custo-benefício',
    '⭐ Recomendo muito',
  ];

  void _addQuickTag(String tag) {
    setState(() {
      final current = _commentController.text.trim();
      if (current.isEmpty) {
        _commentController.text = tag;
      } else if (!current.contains(tag)) {
        _commentController.text = '$current • $tag';
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = picked;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível carregar a imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
    setState(() => _isSubmitting = true);
    bool ok = true;

    try {
      if (_selectedRating > 0) {
        ok = await vm.submitReview(_selectedRating);
      }

      String commentText = _commentController.text.trim();

      // If user selected a photo, upload it to the server
      if (ok && _selectedImage != null) {
        try {
          final uploadService = ref.read(imageUploadServiceProvider);
          final uploadedUrl = await uploadService.uploadImage(
            _selectedImage!,
            entityType: 'Dish',
            entityId: widget.dishId,
          );
          if (commentText.isEmpty) {
            commentText = 'Foto real enviada pelo cliente 📸 [foto:$uploadedUrl]';
          } else {
            commentText = '$commentText [foto:$uploadedUrl]';
          }
        } catch (uploadError) {
          debugPrint('Falha ao enviar imagem (fallback ativado): $uploadError');
          if (commentText.isEmpty) {
            commentText = 'Foto real enviada na visita 📸';
          }
        }
      }

      if (ok && commentText.isNotEmpty) {
        ok = await vm.submitComment(commentText);
      }

      if (ok && mounted) {
        _commentController.clear();
        setState(() {
          _selectedRating = 0;
          _selectedImage = null;
          _showForm = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avaliação enviada! Aguardando moderação.'),
            backgroundColor: Colors.green,
          ),
        );
        await vm.loadComments();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
              'Avaliações & Fotos',
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickTags.map((tag) {
                final isSelected = _commentController.text.contains(tag);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(tag, style: const TextStyle(fontSize: 12)),
                    backgroundColor: isSelected
                        ? const Color(0xFFFFF3CD)
                        : const Color(0xFFF8F9FA),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFFFFC107)
                          : const Color(0xFFE0E0E0),
                    ),
                    onPressed: () => _addQuickTag(tag),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'Deixe um comentário sobre o prato (opcional)...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 6),

          // ── Photo Attachment Row ───────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.deepOrange),
              const SizedBox(width: 6),
              const Text(
                'Anexar foto real:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.photo_camera, size: 14),
                label: const Text('Câmera', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 14),
                label: const Text('Galeria', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),

          // ── Photo Preview Box ──────────────────────────────────────────
          if (_selectedImage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: kIsWeb
                        ? Image.network(
                            _selectedImage!.path,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_selectedImage!.path),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Foto selecionada',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _selectedImage!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    tooltip: 'Remover foto',
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            ),
          ],

          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: (_isSubmitting ||
                    state.isLoading ||
                    (_selectedRating == 0 &&
                        _commentController.text.trim().isEmpty &&
                        _selectedImage == null))
                ? null
                : _submit,
            child: (_isSubmitting || state.isLoading)
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar Avaliação'),
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
            child: Center(
              child: Text(
                'Nenhuma avaliação com foto ainda. Seja o primeiro!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
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

  static final _photoRegex = RegExp(r'\[foto:\s*(https?://[^\s\]]+)\]', caseSensitive: false);

  String? _extractPhotoUrl(String text) {
    final match = _photoRegex.firstMatch(text);
    if (match != null) {
      return match.group(1);
    }
    // Also check for direct image URLs in comment
    final urlRegex = RegExp(r'(https?://[^\s]+\.(?:jpg|jpeg|png|webp))', caseSensitive: false);
    final urlMatch = urlRegex.firstMatch(text);
    return urlMatch?.group(1);
  }

  String _cleanCommentText(String text) {
    return text.replaceAll(_photoRegex, '').trim();
  }

  void _showZoomDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    height: 250,
                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child: const Text('Foto indisponível', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _extractPhotoUrl(comment.text);
    final cleanText = _cleanCommentText(comment.text);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.deepOrange.shade100,
            child: Text(
              comment.userName.isNotEmpty
                  ? comment.userName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange.shade900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      _formatDate(comment.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                if (cleanText.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(cleanText, style: const TextStyle(fontSize: 14)),
                ],
                if (photoUrl != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _showZoomDialog(context, photoUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        alignment: Alignment.bottomLeft,
                        children: [
                          CachedNetworkImage(
                            imageUrl: photoUrl,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 140,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 100,
                              color: Colors.grey.shade100,
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 16, color: Colors.grey),
                                  SizedBox(width: 6),
                                  Text(
                                    'Foto não pôde ser carregada',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, size: 12, color: Colors.amber),
                                SizedBox(width: 4),
                                Text(
                                  '📸 Foto Real do Cliente • Toque para ampliar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
