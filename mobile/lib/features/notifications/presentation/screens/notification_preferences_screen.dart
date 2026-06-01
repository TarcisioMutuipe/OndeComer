import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/notification_preferences_viewmodel.dart';

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPreferencesViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferências de Notificação'),
      ),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erro: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(notificationPreferencesViewModelProvider.notifier)
                    .load(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (prefs) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Receber notificações quando:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Novo comentário'),
              subtitle:
                  const Text('Alguém comenta em um prato do seu restaurante'),
              value: prefs.newComment,
              onChanged: (v) => ref
                  .read(notificationPreferencesViewModelProvider.notifier)
                  .toggleNewComment(v),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Nova avaliação'),
              subtitle: const Text('Alguém avalia um prato do seu restaurante'),
              value: prefs.newReview,
              onChanged: (v) => ref
                  .read(notificationPreferencesViewModelProvider.notifier)
                  .toggleNewReview(v),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Promoções'),
              subtitle:
                  const Text('Restaurantes que você segue lançam promoções'),
              value: prefs.promotionActive,
              onChanged: (v) => ref
                  .read(notificationPreferencesViewModelProvider.notifier)
                  .togglePromotionActive(v),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Novos pratos'),
              subtitle: const Text(
                  'Restaurantes que você segue adicionam novos pratos'),
              value: prefs.newDish,
              onChanged: (v) => ref
                  .read(notificationPreferencesViewModelProvider.notifier)
                  .toggleNewDish(v),
            ),
          ],
        ),
      ),
    );
  }
}
