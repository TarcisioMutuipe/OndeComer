import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../viewmodels/checkin_viewmodel.dart';

class CheckInHistoryScreen extends ConsumerWidget {
  const CheckInHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(checkInHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Check-ins'),
      ),
      body: historyState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erro: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(checkInHistoryProvider.notifier).load(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (history) {
          if (history == null || history.checkIns.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Nenhum check-in realizado ainda.',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Column(
                  children: [
                    const Text('Total de Pontos',
                        style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      '${history.totalPoints}',
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.checkIns.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = history.checkIns[index];
                    final dateStr = DateFormat('dd/MM/yyyy HH:mm')
                        .format(item.checkInTime.toLocal());
                    return ListTile(
                      leading: Icon(
                        item.isValidated ? Icons.check_circle : Icons.cancel,
                        color: item.isValidated ? Colors.green : Colors.orange,
                      ),
                      title: Text(item.restaurantName),
                      subtitle: Text(dateStr),
                      trailing: item.isValidated
                          ? Text('+${item.pointsAwarded}',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold))
                          : const Text('Longe',
                              style: TextStyle(color: Colors.orange)),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
