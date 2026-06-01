import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Shows a friendly bottom sheet when user attempts an action offline.
/// Returns the preserved [formData] to the caller so the form is not lost.
Future<void> showOfflineActionModal(
  BuildContext context, {
  String? preservedText,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Icon(Icons.wifi_off_rounded,
              size: 48, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          const Text(
            'Sem conexão com a internet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esta ação requer conexão. Tente novamente quando estiver online.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
          if (preservedText != null && preservedText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(children: [
                const Icon(Icons.save_outlined,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Texto preservado: "$preservedText"',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                foregroundColor: AppTheme.textPrimary,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Entendido'),
            ),
          ),
        ],
      ),
    ),
  );
}
