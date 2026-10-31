import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:onde_comer_em_salvador/features/admin/data/datasources/admin_restaurant_datasource.dart';
import 'package:onde_comer_em_salvador/features/admin/presentation/viewmodels/admin_restaurant_viewmodel.dart';
import 'package:onde_comer_em_salvador/features/restaurant/data/models/restaurant_model.dart';

class AdminRestaurantListScreen extends ConsumerStatefulWidget {
  const AdminRestaurantListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminRestaurantListScreen> createState() =>
      _AdminRestaurantListScreenState();
}

class _AdminRestaurantListScreenState
    extends ConsumerState<AdminRestaurantListScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    Future.microtask(() {
      ref.read(adminRestaurantProvider.notifier).loadRestaurants();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(adminRestaurantProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Restaurantes'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Criar restaurante',
            onPressed: () => _openRestaurantForm(context),
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
                hintText: 'Buscar restaurante...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                ref.read(adminRestaurantProvider.notifier).loadRestaurants(
                      search: value.isEmpty ? null : value,
                    );
              },
            ),
          ),
          // Restaurants list
          Expanded(
            child: restaurantsAsync.when(
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
              data: (restaurants) {
                if (restaurants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Nenhum restaurante encontrado',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                final duplicateEntries =
                    restaurants.where((entry) => entry.hasDuplicateName).toList();
                final duplicateNameCount = duplicateEntries
                    .map((entry) => entry.restaurant.name.trim().toLowerCase())
                    .toSet()
                    .length;

                return Column(
                  children: [
                    if (duplicateEntries.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          border: Border.all(color: Colors.amber.shade700),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.amber.shade900),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(duplicateEntries.any((entry) =>
                                      entry.hasAdminAndUserDuplicate)
                                  ? 'Foi cadastrado por um usuário um restaurante com o mesmo nome.'
                                  : '$duplicateNameCount nome(s) de restaurante duplicado(s).'),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: restaurants.length,
                        itemBuilder: (context, index) {
                          final entry = restaurants[index];
                          final restaurant = entry.restaurant;
                          return _RestaurantCard(
                            entry: entry,
                            onEdit: () => _editRestaurant(context, restaurant),
                            onDelete: () =>
                                _deleteRestaurant(context, restaurant.id),
                            onManageDishes: () =>
                                _manageDishes(context, restaurant),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editRestaurant(
      BuildContext context, RestaurantModel restaurant) async {
    await _openRestaurantForm(context, restaurant: restaurant);
  }

  Future<void> _openRestaurantForm(BuildContext context,
      {RestaurantModel? restaurant}) async {
    final saved = await context.push<bool>(
      '/restaurant/form?admin=true',
      extra: restaurant,
    );
    if (!mounted || saved != true) return;
    await ref.read(adminRestaurantProvider.notifier).loadRestaurants(
          search: _searchController.text.isEmpty ? null : _searchController.text,
        );
  }

  void _deleteRestaurant(BuildContext context, String restaurantId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar Restaurante'),
        content: const Text('Tem certeza que deseja deletar este restaurante?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final deleted = await ref
                  .read(adminRestaurantProvider.notifier)
                  .deleteRestaurant(restaurantId);
              if (!mounted) return;
              if (deleted) {
                await ref.read(adminRestaurantProvider.notifier).loadRestaurants(
                      search: _searchController.text.isEmpty
                          ? null
                          : _searchController.text,
                    );
              }
              if (!mounted) return;
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(deleted
                      ? 'Restaurante deletado'
                      : 'Não foi possível deletar o restaurante'),
                ),
              );
            },
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _manageDishes(BuildContext context, RestaurantModel restaurant) {
    context.push('/admin/restaurant/${restaurant.id}/dishes');
  }
}

class _RestaurantCard extends StatelessWidget {
  final AdminRestaurantEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageDishes;

  const _RestaurantCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    required this.onManageDishes,
  });

  @override
  Widget build(BuildContext context) {
    final restaurant = entry.restaurant;
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
                if (restaurant.coverUrl != null &&
                    restaurant.coverUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      restaurant.coverUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant),
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
                        restaurant.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant.category ?? 'Sem categoria',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant.city ?? 'Cidade desconhecida',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant.address.isEmpty
                            ? 'Endereço não informado'
                            : restaurant.address,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (entry.hasDuplicateName)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: Colors.deepOrange.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry.hasAdminAndUserDuplicate
                            ? 'Foi cadastrado por um usuário um restaurante com o mesmo nome.'
                            : 'Existe outro restaurante com este nome.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.deepOrange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            // YouTube URL status
            if (restaurant.youTubeVideoUrl != null &&
                restaurant.youTubeVideoUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.video_library, size: 16, color: Colors.red),
                    const SizedBox(width: 6),
                    Text(
                      'Vídeo YouTube vinculado',
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
                    ),
                  ],
                ),
              ),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onManageDishes,
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Pratos'),
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
