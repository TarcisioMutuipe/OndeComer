import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/offline/sync_processor.dart';
import '../../core/theme/app_theme.dart';

/// Badge shown in AppBar or scaffold when there are pending sync operations.
class SyncPendingBadge extends ConsumerWidget {
  const SyncPendingBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncProcessorProvider);

    if (!sync.hasPending && !sync.isSyncing) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: sync.isSyncing
            ? 'Sincronizando...'
            : '${sync.pendingCount} ação(ões) pendente(s)',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sync.isSyncing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryYellowDark,
                ),
              )
            else
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.cloud_upload_outlined,
                      size: 22, color: AppTheme.primaryYellowDark),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '${sync.pendingCount}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
