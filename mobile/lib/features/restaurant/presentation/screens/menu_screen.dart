import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../data/models/dish_model.dart';
import '../../data/models/restaurant_model.dart';
import '../viewmodels/dish_viewmodel.dart';
import '../viewmodels/restaurant_list_viewmodel.dart';

class MenuScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  final String? initialCategory;
  final String? initialSubcategory;
  final String? focusDishId;

  const MenuScreen({
    super.key,
    required this.restaurantId,
    this.initialCategory,
    this.initialSubcategory,
    this.focusDishId,
  });

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  late String _selectedCategory;
  String _selectedSubcategory = 'Todas';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'Todos';
    _selectedSubcategory = widget.initialSubcategory ?? 'Todas';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(dishViewModelProvider(widget.restaurantId).notifier)
          .loadDishes(onlyAvailable: true);
      unawaited(_offerAppDownload());
    });
  }

  Future<void> _offerAppDownload() async {
    if (!kIsWeb || !mounted || MediaQuery.sizeOf(context).width > 700) return;

    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final storeUrl = Uri.parse(isIos
        ? 'https://apps.apple.com/br/search?term=Onde%20Comer%20Em%20Salvador'
        : 'https://play.google.com/store/apps/details?id=com.ondecomer.emsalvador');

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant_menu,
                color: AppTheme.primaryYellowDark, size: 32),
            const SizedBox(height: 10),
            Text(
              'Conheça o app Onde Comer em Salvador',
              textAlign: TextAlign.center,
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Você também pode continuar vendo este cardápio pelo navegador.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final opened = await launchUrl(
                    storeUrl,
                    mode: LaunchMode.externalApplication,
                  );
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  if (!opened && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Não foi possível abrir a loja.')),
                    );
                  }
                },
                icon: const Icon(Icons.download_outlined),
                label: const Text('Ver opção de download'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Continuar no navegador'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dishViewModelProvider(widget.restaurantId));
    final restaurant = ref.watch(restaurantDetailProvider(widget.restaurantId));
    final menuDishes = state.dishes.where((dish) => dish.isActive).toList();
    final categories = <String>[
      'Todos',
      ..._menuSections.where((section) =>
          menuDishes.any((dish) => _sectionName(dish.category) == section)),
    ];
    final categoryDishes = menuDishes.where((dish) =>
        _selectedCategory == 'Todos' ||
        _sectionName(dish.category) == _selectedCategory);
    final subcategories = <String>[
      'Todas',
      ...categoryDishes
          .map((dish) => dish.subcategory?.trim() ?? '')
          .where((subcategory) => subcategory.isNotEmpty)
          .toSet()
          .toList()
        ..sort(),
    ];
    final filteredDishes = categoryDishes.where((dish) {
      final matchesSubcategory = _selectedSubcategory == 'Todas' ||
          dish.subcategory?.trim() == _selectedSubcategory;
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          dish.name.toLowerCase().contains(query) ||
          (dish.description?.toLowerCase().contains(query) ?? false);
      return matchesSubcategory && matchesSearch;
    }).toList();
    final dishesByCategory = <String, List<DishModel>>{};
    for (final dish in filteredDishes) {
      dishesByCategory
          .putIfAbsent(_sectionName(dish.category), () => [])
          .add(dish);
    }
    final categoryOrder = [
      ..._menuSections,
      ...dishesByCategory.keys.where((key) => !_menuSections.contains(key)),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(restaurant.valueOrNull?.name ?? 'Cardápio'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (restaurant.valueOrNull != null)
              _MenuHeader(restaurant: restaurant.valueOrNull!),
            _CategoryBar(
              categories: categories,
              selectedCategory: _selectedCategory,
              onSelected: (category) => setState(() {
                _selectedCategory = category;
                _selectedSubcategory = 'Todas';
              }),
            ),
            if (_selectedCategory != 'Todos' && subcategories.length > 1)
              _SubcategoryBar(
                subcategories: subcategories,
                selectedSubcategory: _selectedSubcategory,
                onSelected: (subcategory) =>
                    setState(() => _selectedSubcategory = subcategory),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Buscar no menu',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: () => setState(() {
                            _searchCtrl.clear();
                            _searchQuery = '';
                          }),
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primaryYellowDark,
                onRefresh: () => ref
                    .read(dishViewModelProvider(widget.restaurantId).notifier)
                    .loadDishes(onlyAvailable: true),
                child: Builder(
                  builder: (context) {
                    if (state.isLoading && menuDishes.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.error != null && menuDishes.isEmpty) {
                      return _MenuMessage(
                        message: state.error!,
                        actionLabel: 'Tentar novamente',
                        onPressed: () => ref
                            .read(dishViewModelProvider(widget.restaurantId)
                                .notifier)
                            .loadDishes(onlyAvailable: true),
                      );
                    }
                    if (filteredDishes.isEmpty) {
                      return const _MenuMessage(
                        message: 'Nenhum item encontrado neste menu.',
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final maxContentWidth = constraints.maxWidth > 900
                            ? 900.0
                            : constraints.maxWidth;
                        return Center(
                          child: SizedBox(
                            width: maxContentWidth,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                              children: [
                                for (final category in categoryOrder)
                                  if (dishesByCategory[category]?.isNotEmpty ??
                                      false)
                                    _MenuCategorySection(
                                      title: _selectedCategory == 'Todos'
                                          ? category
                                          : null,
                                      dishes: dishesByCategory[category]!,
                                      focusDishId: widget.focusDishId,
                                    ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _menuSections = [
  'Entradas',
  'Menu Principal',
  'Petiscos',
  'Sobremesas',
  'Bebidas',
  'Carta de Vinhos',
];

String _sectionName(String category) {
  final normalized = category.trim().toLowerCase();
  if (normalized.contains('entrada')) return 'Entradas';
  if (normalized.contains('principal')) return 'Menu Principal';
  if (normalized.contains('sobremesa')) return 'Sobremesas';
  if (normalized.contains('petisco')) return 'Petiscos';
  if (normalized.contains('bebid') || normalized.contains('drink'))
    return 'Bebidas';
  if (normalized.contains('vinho')) return 'Carta de Vinhos';
  return category.trim().isEmpty ? 'Outros' : category.trim();
}

class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const _CategoryBar({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 52,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            final selected = category == selectedCategory;
            return ChoiceChip(
              selected: selected,
              onSelected: (_) => onSelected(category),
              label: Text(category),
              selectedColor: AppTheme.primaryYellow,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected ? AppTheme.primaryYellowDark : AppTheme.divider,
              ),
              labelStyle: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            );
          },
        ),
      );
}

class _SubcategoryBar extends StatelessWidget {
  final List<String> subcategories;
  final String selectedSubcategory;
  final ValueChanged<String> onSelected;

  const _SubcategoryBar({
    required this.subcategories,
    required this.selectedSubcategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        alignment: Alignment.centerLeft,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.divider)),
          color: Colors.white,
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: subcategories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 18),
          itemBuilder: (context, index) {
            final subcategory = subcategories[index];
            final selected = subcategory == selectedSubcategory;
            return InkWell(
              onTap: () => onSelected(subcategory),
              child: Center(
                child: Text(
                  subcategory,
                  style: TextStyle(
                    color: selected
                        ? AppTheme.primaryYellowDark
                        : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _MenuCategorySection extends StatelessWidget {
  final String? title;
  final List<DishModel> dishes;
  final String? focusDishId;

  const _MenuCategorySection({
    required this.title,
    required this.dishes,
    required this.focusDishId,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<DishModel>>{};
    for (final dish in dishes) {
      final subcategory = dish.subcategory?.trim();
      grouped
          .putIfAbsent(
            subcategory == null || subcategory.isEmpty
                ? 'Destaques'
                : subcategory,
            () => [],
          )
          .add(dish);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) _MenuSectionHeading(title: title!),
        for (final entry in grouped.entries) ...[
          _MenuSectionHeading(title: entry.key, compact: true),
          for (final dish in entry.value)
            _MenuDishCard(
              dish: dish,
              highlighted: dish.id == focusDishId,
            ),
        ],
      ],
    );
  }
}

class _MenuSectionHeading extends StatelessWidget {
  final String title;
  final bool compact;

  const _MenuSectionHeading({required this.title, this.compact = false});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(4, compact ? 12 : 18, 4, 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: compact ? Colors.transparent : Colors.white,
          border: compact
              ? const Border(
                  left: BorderSide(color: AppTheme.primaryYellowDark, width: 3))
              : Border(bottom: const BorderSide(color: AppTheme.divider)),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: compact ? 15 : 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _MenuDishCard extends StatelessWidget {
  final DishModel dish;
  final bool highlighted;

  const _MenuDishCard({required this.dish, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    final imageSize = MediaQuery.sizeOf(context).width < 420 ? 92.0 : 112.0;
    return Card(
      margin: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      color: highlighted ? const Color(0xFFFFF8E1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: highlighted ? AppTheme.primaryYellowDark : AppTheme.divider,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: dish.imageUrl != null && dish.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: dish.imageUrl!,
                      width: imageSize,
                      height: imageSize,
                      fit: BoxFit.cover,
                      memCacheWidth: 400,
                      memCacheHeight: 400,
                      placeholder: (_, __) => const SkeletonLoader(
                        width: 100,
                        height: 100,
                        borderRadius: 8,
                      ),
                      errorWidget: (_, __, ___) =>
                          _DishImagePlaceholder(size: imageSize),
                    )
                  : _DishImagePlaceholder(size: imageSize),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: imageSize),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dish.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.primaryYellowDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (dish.description?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 5),
                      Text(
                        dish.description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'R\$ ${dish.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DishImagePlaceholder extends StatelessWidget {
  final double size;

  const _DishImagePlaceholder({required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        color: const Color(0xFFFFF2CC),
        child: const Icon(Icons.restaurant, color: AppTheme.primaryYellowDark),
      );
}

class _MenuMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  const _MenuMessage({
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 64),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          if (actionLabel != null && onPressed != null)
            TextButton(onPressed: onPressed, child: Text(actionLabel!)),
        ],
      );
}

class _MenuHeader extends StatelessWidget {
  final RestaurantModel restaurant;

  const _MenuHeader({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final coverUrl = restaurant.coverUrl;
    return SizedBox(
      height: 224,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverUrl != null && coverUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              memCacheWidth: 1200,
              errorWidget: (_, __, ___) =>
                  Container(color: AppTheme.textPrimary),
            )
          else
            Container(color: AppTheme.textPrimary),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xD9000000)],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (restaurant.category.isNotEmpty)
                  Text(
                    restaurant.category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  restaurant.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  [restaurant.address, restaurant.city]
                      .where((value) => value.trim().isNotEmpty)
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
