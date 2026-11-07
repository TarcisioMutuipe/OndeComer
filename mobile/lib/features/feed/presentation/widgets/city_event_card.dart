import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/models/city_event_model.dart';
import '../viewmodels/feed_viewmodel.dart';

class CityEventCard extends ConsumerWidget {
  final CityEventModel event;

  const CityEventCard({super.key, required this.event});

  Future<void> _openYouTube(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o link do vídeo.')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link de vídeo inválido.')),
        );
      }
    }
  }

  void _handleReaction(BuildContext context, WidgetRef ref, bool isLike) {
    final auth = ref.read(authViewModelProvider);
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para interagir com os eventos!')),
      );
      return;
    }
    ref.read(feedViewModelProvider.notifier).reactToEvent(event.id, isLike);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasYouTube = event.youTubeVideoUrl != null && event.youTubeVideoUrl!.isNotEmpty;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Header / Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.amber.shade50,
            child: Row(
              children: [
                const Icon(Icons.event_available, color: Colors.deepOrange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.restaurantName != null
                        ? 'Novidade: ${event.restaurantName}'
                        : 'Evento em Salvador',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
                Text(
                  DateFormat('dd/MM').format(event.createdAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),

          // Event Image
          if (event.imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: event.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                ),
              ),
            ),

          // Title & Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
                ),
                if (event.eventDate != null || (event.locationOrAddress != null && event.locationOrAddress!.isNotEmpty)) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      if (event.eventDate != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 15, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(event.eventDate!.toLocal()),
                              style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      if (event.locationOrAddress != null && event.locationOrAddress!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(
                              event.locationOrAddress!,
                              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // YouTube button if present
          if (hasYouTube)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.play_circle_fill, color: Colors.red),
                label: const Text('Assistir no YouTube', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _openYouTube(context, event.youTubeVideoUrl!),
              ),
            ),

          const Divider(height: 1),

          // Footer: Curtir / Não curtir
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                // Curtir button
                TextButton.icon(
                  onPressed: () => _handleReaction(context, ref, true),
                  icon: Icon(
                    event.userReaction == true ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 18,
                    color: event.userReaction == true ? AppTheme.primaryYellowDark : Colors.grey.shade700,
                  ),
                  label: Text(
                    '${event.likesCount}',
                    style: TextStyle(
                      fontWeight: event.userReaction == true ? FontWeight.bold : FontWeight.normal,
                      color: event.userReaction == true ? AppTheme.primaryYellowDark : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Não curtir button
                TextButton.icon(
                  onPressed: () => _handleReaction(context, ref, false),
                  icon: Icon(
                    event.userReaction == false ? Icons.thumb_down : Icons.thumb_down_outlined,
                    size: 18,
                    color: event.userReaction == false ? Colors.red.shade700 : Colors.grey.shade700,
                  ),
                  label: Text(
                    '${event.dislikesCount}',
                    style: TextStyle(
                      fontWeight: event.userReaction == false ? FontWeight.bold : FontWeight.normal,
                      color: event.userReaction == false ? Colors.red.shade700 : Colors.grey.shade700,
                    ),
                  ),
                ),

                const Spacer(),
                const Text(
                  'Gostou do evento?',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

