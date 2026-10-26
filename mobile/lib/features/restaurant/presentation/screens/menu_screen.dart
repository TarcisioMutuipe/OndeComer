import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../viewmodels/dish_viewmodel.dart';

class MenuScreen extends ConsumerStatefulWidget {
  final String restaurantId;

  const MenuScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String _selectedCategory = 'Todos';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dishViewModelProvider(widget.restaurantId));

    // Extract categories
    final categories = <String>['Todos'];
    for (final d in state.dishes) {
      if (!categories.contains(d.category)) {
        categories.add(d.category);
      }
    }

    // Filter dishes
    final filteredDishes = state.dishes.where((dish) {
      final matchesCategory = _selectedCategory == 'Todos' ||
          dish.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          dish.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (dish.description != null &&
              dish.description!
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesSearch;
    }).toList();

    // Group by category
    final Map<String, List<dynamic>> grouped = {};
    for (final dish in filteredDishes) {
      grouped.putIfAbsent(dish.category, () => []).add(dish);
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Cardápio'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Buscar prato no cardápio…',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.background,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              if (categories.length > 1)
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        selected: isSelected,
                        label: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                          ),
                        ),
                        backgroundColor: AppTheme.background,
                        selectedColor: AppTheme.primaryYellow,
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.primaryYellow
                              : AppTheme.divider,
                        ),
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryYellow,
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

            if (filteredDishes.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Nenhum prato encontrado com os filtros aplicados.',
                      style: TextStyle(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center),
                ),
              );
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
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            onTap: () =>
                                context.push('/dish/${dish.id}', extra: dish),
                            leading: dish.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: dish.imageUrl!,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 150,
                                      memCacheHeight: 150,
                                      placeholder: (_, __) =>
                                          const SkeletonLoader(
                                              width: 56,
                                              height: 56,
                                              borderRadius: 8),
                                      errorWidget: (_, __, ___) => const Icon(
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
                            title: Text(dish.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
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
                                    color: AppTheme.primaryYellowDark,
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
