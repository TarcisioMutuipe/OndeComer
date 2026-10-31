import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onde_comer_em_salvador/features/admin/presentation/viewmodels/admin_dish_viewmodel.dart';
import 'package:onde_comer_em_salvador/features/restaurant/data/models/dish_model.dart';

class AdminDishListScreen extends ConsumerStatefulWidget {
  final String restaurantId;

  const AdminDishListScreen({
    Key? key,
    required this.restaurantId,
  }) : super(key: key);

  @override
  ConsumerState<AdminDishListScreen> createState() =>
      _AdminDishListScreenState();
}

class _AdminDishListScreenState extends ConsumerState<AdminDishListScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    Future.microtask(() {
      ref.read(adminDishProvider.notifier).loadDishes(widget.restaurantId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dishesAsync = ref.watch(adminDishProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Pratos'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Criar prato',
            onPressed: () => _openDishForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar prato...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                ref.read(adminDishProvider.notifier).loadDishes(
                      widget.restaurantId,
                      search: value.isEmpty ? null : value,
                    );
              },
            ),
          ),
          // Dishes list
          Expanded(
            child: dishesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Erro ao carregar: $error'),
                  ],
                ),
              ),
              data: (dishes) {
                if (dishes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fastfood, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Nenhum prato encontrado',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: dishes.length,
                  itemBuilder: (context, index) {
                    final dish = dishes[index];
                    return _DishCard(
                      dish: dish,
                      onEdit: () => _editDish(context, dish),
                      onDelete: () => _deleteDish(context, dish.id),
                      onToggleAvailability: () =>
                          _toggleAvailability(context, dish.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDishForm(BuildContext context, {DishModel? dish}) async {
    final saved = await context.push<bool>(
      '/restaurant/${widget.restaurantId}/dish/form',
      extra: dish,
    );
    if (!mounted || saved != true) return;
    await ref.read(adminDishProvider.notifier).loadDishes(widget.restaurantId);
  }

  Future<void> _editDish(BuildContext context, DishModel dish) async {
    await _openDishForm(context, dish: dish);
  }

  void _deleteDish(BuildContext context, String dishId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar Prato'),
        content: const Text('Tem certeza que deseja deletar este prato?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(adminDishProvider.notifier).deleteDish(dishId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prato deletado')),
              );
            },
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleAvailability(BuildContext context, String dishId) {
    ref.read(adminDishProvider.notifier).toggleAvailability(dishId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Disponibilidade alterada')),
    );
  }
}

class _DishCard extends StatelessWidget {
  final DishModel dish;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;

  const _DishCard({
    required this.dish,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Image
                if (dish.imageUrl != null && dish.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      dish.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.fastfood),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dish.category ?? 'Sem categoria',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'R\$ ${dish.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Availability status
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: dish.isActive ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    dish.isActive ? 'Disponível' : 'Indisponível',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          dish.isActive ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onToggleAvailability,
                  icon: Icon(
                      dish.isActive ? Icons.visibility : Icons.visibility_off),
                  label: Text(dish.isActive ? 'Ocultar' : 'Mostrar'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Deletar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
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
