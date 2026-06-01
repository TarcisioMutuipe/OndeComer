import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/dish_viewmodel.dart';

class MenuScreen extends ConsumerStatefulWidget {
  final String restaurantId;

  const MenuScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(dishViewModelProvider(widget.restaurantId).notifier)
          .loadDishes(onlyAvailable: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dishViewModelProvider(widget.restaurantId));

    return Scaffold(
      appBar: AppBar(title: const Text('Cardápio')),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(dishViewModelProvider(widget.restaurantId).notifier)
            .loadDishes(onlyAvailable: true),
        child: Builder(
          builder: (context) {
            if (state.isLoading && state.dishes.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(state.error!),
                    TextButton(
                      onPressed: () => ref
                          .read(dishViewModelProvider(widget.restaurantId)
                              .notifier)
                          .loadDishes(onlyAvailable: true),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            }

            if (state.dishes.isEmpty) {
              return const Center(
                  child: Text('Nenhum item disponível no momento.'));
            }

            // Group by category
            final Map<String, List<dynamic>> grouped = {};
            for (final dish in state.dishes) {
              grouped.putIfAbsent(dish.category, () => []).add(dish);
            }

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        entry.key,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...entry.value.map((dish) => Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: dish.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      dish.imageUrl!,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.fastfood,
                                          size: 32,
                                          color: Colors.grey),
                                    ),
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.fastfood),
                                  ),
                            title: Text(dish.name),
                            subtitle: dish.description != null
                                ? Text(
                                    dish.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'R\$ ${dish.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (dish.ratingCount > 0)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star,
                                          size: 12, color: Colors.amber),
                                      Text(
                                        dish.ratingAverage.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        )),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/restaurant/${widget.restaurantId}/dish/form'),
        icon: const Icon(Icons.add),
        label: const Text('Novo Prato'),
      ),
    );
  }
}
