import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../restaurant/presentation/widgets/restaurant_card.dart';
import '../../../restaurant/data/models/restaurant_model.dart';
import '../../data/models/restaurant_search_result_model.dart';
import '../viewmodels/search_viewmodel.dart';
import '../widgets/salvador_radar_view.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _filtersExpanded = false;
  String? _selectedNeighborhood;
  bool _isRadarView = false;

  // Local filter state (applied only on "Aplicar")
  String? _localCategory;
  double? _localMinPrice;
  double? _localMaxPrice;
  double? _localMinRating;
  bool? _localIsOpenNow;
  String _localSortBy = 'relevance';
  double _localRadius = 5.0;

  static const _categories = [
    'Comida Baiana',
    'Acarajé & Tabuleiro',
    'Cafés & Docerias',
    'Petiscos & Bar',
    'Nordestina',
    'Frutos do Mar',
    'Pizza',
    'Japonesa',
    'Brasileira',
    'Lanches',
    'Saudável',
    'Vegano',
    'Hambúrguer',
    'Italiana',
    'Árabe',
    'Churrasco',
  ];

  static const _sortOptions = [
    ('relevance', 'Relevância'),
    ('rating', 'Avaliação'),
    ('distance', 'Distância'),
    ('name', 'Nome'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchViewModelProvider.notifier).search(refresh: true);
    });
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(searchViewModelProvider.notifier).search();
    }
  }

  void _onSelectNeighborhood(String neighborhood) {
    setState(() {
      if (_selectedNeighborhood == neighborhood || neighborhood == 'Todos') {
        _selectedNeighborhood = null;
        _queryCtrl.clear();
      } else {
        _selectedNeighborhood = neighborhood;
        _queryCtrl.text = neighborhood;
      }
    });
    _submitQuery();
  }

  void _submitQuery() {
    ref
        .read(searchViewModelProvider.notifier)
        .setQuery(_queryCtrl.text.isEmpty ? null : _queryCtrl.text);
    ref.read(searchViewModelProvider.notifier).search(refresh: true);
  }

  void _applyFilters() {
    ref.read(searchViewModelProvider.notifier).applyFilters(
          category: _localCategory,
          minPrice: _localMinPrice,
          maxPrice: _localMaxPrice,
          minRating: _localMinRating,
          isOpenNow: _localIsOpenNow,
          sortBy: _localSortBy,
        );
    ref.read(searchViewModelProvider.notifier).search(refresh: true);
    setState(() => _filtersExpanded = false);
  }

  void _clearFilters() {
    setState(() {
      _localCategory = null;
      _localMinPrice = null;
      _localMaxPrice = null;
      _localMinRating = null;
      _localIsOpenNow = null;
      _localSortBy = 'relevance';
      _localRadius = 5.0;
      _selectedNeighborhood = null;
    });
    ref.read(searchViewModelProvider.notifier).clearFilters();
    ref.read(searchViewModelProvider.notifier).search(refresh: true);
  }

  void _requestLocation() {
    ref.read(searchViewModelProvider.notifier).requestLocation();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchViewModelProvider);

    if (state.sortBy != _localSortBy && !_filtersExpanded) {
      _localSortBy = state.sortBy;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          _SearchAppBar(
            queryCtrl: _queryCtrl,
            onSubmit: _submitQuery,
            filtersExpanded: _filtersExpanded,
            hasActiveFilters: state.hasActiveFilters,
            selectedNeighborhood: _selectedNeighborhood,
            onSelectNeighborhood: _onSelectNeighborhood,
            onToggleFilters: () =>
                setState(() => _filtersExpanded = !_filtersExpanded),
          ),
          if (_filtersExpanded)
            SliverToBoxAdapter(
              child: _FilterPanel(
                category: _localCategory,
                minPrice: _localMinPrice,
                maxPrice: _localMaxPrice,
                minRating: _localMinRating,
                isOpenNow: _localIsOpenNow,
                sortBy: _localSortBy,
                radius: _localRadius,
                categories: _categories,
                sortOptions: _sortOptions,
                hasLocation: state.userLat != null,
                locationLoading: state.locationLoading,
                locationPermissionDenied: state.locationPermissionDenied,
                onCategoryChanged: (v) => setState(() => _localCategory = v),
                onMinPriceChanged: (v) => setState(() => _localMinPrice = v),
                onMaxPriceChanged: (v) => setState(() => _localMaxPrice = v),
                onMinRatingChanged: (v) => setState(() => _localMinRating = v),
                onIsOpenNowChanged: (v) => setState(() => _localIsOpenNow = v),
                onSortByChanged: (v) =>
                    setState(() => _localSortBy = v ?? 'relevance'),
                onRadiusChanged: (v) => setState(() => _localRadius = v),
                onRequestLocation: _requestLocation,
                onClearLocation: () {
                  ref.read(searchViewModelProvider.notifier).clearLocation();
                  setState(() => _localSortBy = 'relevance');
                },
                onApply: _applyFilters,
                onClear: _clearFilters,
              ),
            ),
          if (state.locationPermissionDenied && !_filtersExpanded)
            const SliverToBoxAdapter(child: _LocationDeniedBanner()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text(
                    _isRadarView
                        ? 'Explorador Radar Salvador'
                        : 'Restaurantes (${state.results.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _isRadarView = !_isRadarView),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isRadarView
                            ? AppTheme.primaryYellow
                            : AppTheme.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isRadarView
                              ? AppTheme.primaryYellowDark
                              : AppTheme.divider,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isRadarView ? Icons.list_alt : Icons.radar,
                            size: 15,
                            color: AppTheme.textPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isRadarView ? 'Ver Lista' : 'Modo Radar',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, __) => const RestaurantSkeletonCard(),
                childCount: 6,
              ),
            )
          else if (_isRadarView)
            SliverToBoxAdapter(
              child: SalvadorRadarView(
                results: state.results,
                userLat: state.userLat,
                userLng: state.userLng,
                onSelectRestaurant: (r) => context.push('/restaurant/${r.id}'),
                onSelectCircuit: _onSelectNeighborhood,
              ),
            )
          else if (state.results.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off,
                          size: 64, color: AppTheme.textSecondary),
                      SizedBox(height: 12),
                      Text('Nenhum resultado encontrado.',
                          style: TextStyle(color: AppTheme.textSecondary),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final r = state.results[i];
                    return _SearchResultCard(
                      result: r,
                      onTap: () => context.push('/restaurant/${r.id}'),
                    );
                  },
                  childCount: state.results.length,
                ),
              ),
            ),
            if (state.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── AppBar as sliver ─────────────────────────────────────────────────────────

class _SearchAppBar extends StatelessWidget {
  final TextEditingController queryCtrl;
  final VoidCallback onSubmit;
  final bool filtersExpanded;
  final bool hasActiveFilters;
  final VoidCallback onToggleFilters;
  final String? selectedNeighborhood;
  final ValueChanged<String> onSelectNeighborhood;

  const _SearchAppBar({
    required this.queryCtrl,
    required this.onSubmit,
    required this.filtersExpanded,
    required this.hasActiveFilters,
    required this.onToggleFilters,
    this.selectedNeighborhood,
    required this.onSelectNeighborhood,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppTheme.white,
      elevation: 0,
      titleSpacing: 0,
      title: const Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text('Busca Avançada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(104),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
            children: [
              Expanded(
                child: TextField(
                  controller: queryCtrl,
                  onSubmitted: (_) => onSubmit(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Pizza, frutos do mar, japonês…',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: queryCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              queryCtrl.clear();
                              onSubmit();
                            })
                        : null,
                    filled: true,
                    fillColor: AppTheme.background,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: filtersExpanded
                          ? AppTheme.primaryYellow
                          : AppTheme.background,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.tune, size: 22),
                    onPressed: onToggleFilters,
                    tooltip: 'Filtros',
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                'Todos',
                'Rio Vermelho',
                'Pelourinho',
                'Barra',
                'Pituba',
                'Ribeira',
                'Itapuã',
                'Stella Maris',
                'Santo Antônio',
              ].map((hub) {
                final isSelected =
                    (selectedNeighborhood == null && hub == 'Todos') ||
                        selectedNeighborhood == hub;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      hub,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryYellow,
                    backgroundColor: AppTheme.white,
                    side: BorderSide(
                      color:
                          isSelected ? AppTheme.primaryYellow : AppTheme.divider,
                      width: 1,
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onSelected: (_) => onSelectNeighborhood(hub),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

// ── Filter panel ─────────────────────────────────────────────────────────────

class _FilterPanel extends StatelessWidget {
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final bool? isOpenNow;
  final String sortBy;
  final double radius;
  final List<String> categories;
  final List<(String, String)> sortOptions;
  final bool hasLocation;
  final bool locationLoading;
  final bool locationPermissionDenied;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<double?> onMinPriceChanged;
  final ValueChanged<double?> onMaxPriceChanged;
  final ValueChanged<double?> onMinRatingChanged;
  final ValueChanged<bool?> onIsOpenNowChanged;
  final ValueChanged<String?> onSortByChanged;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onRequestLocation;
  final VoidCallback onClearLocation;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const _FilterPanel({
    required this.category,
    required this.minPrice,
    required this.maxPrice,
    required this.minRating,
    required this.isOpenNow,
    required this.sortBy,
    required this.radius,
    required this.categories,
    required this.sortOptions,
    required this.hasLocation,
    required this.locationLoading,
    required this.locationPermissionDenied,
    required this.onCategoryChanged,
    required this.onMinPriceChanged,
    required this.onMaxPriceChanged,
    required this.onMinRatingChanged,
    required this.onIsOpenNowChanged,
    required this.onSortByChanged,
    required this.onRadiusChanged,
    required this.onRequestLocation,
    required this.onClearLocation,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cozinha ──────────────────────────────────────────────────
          _SectionLabel('Cozinha'),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: categories.map((cat) {
                final sel = cat == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat,
                        style: TextStyle(
                            fontSize: 12,
                            color: sel
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary)),
                    selected: sel,
                    selectedColor: AppTheme.primaryYellow,
                    backgroundColor: AppTheme.background,
                    checkmarkColor: AppTheme.textPrimary,
                    side: BorderSide.none,
                    onSelected: (_) => onCategoryChanged(sel ? null : cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // ── Preço ────────────────────────────────────────────────────
          _SectionLabel('Preço do prato (R\$)'),
          Row(children: [
            Expanded(
              child: _NumberField(
                label: 'Mínimo',
                value: minPrice,
                onChanged: onMinPriceChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                label: 'Máximo',
                value: maxPrice,
                onChanged: onMaxPriceChanged,
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // ── Nota mínima ──────────────────────────────────────────────
          _SectionLabel('Avaliação mínima'),
          Row(
            children: [1, 2, 3, 4, 5].map((star) {
              final sel = minRating != null && minRating! >= star;
              return GestureDetector(
                onTap: () => onMinRatingChanged(
                    minRating == star.toDouble() ? null : star.toDouble()),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    sel ? Icons.star_rounded : Icons.star_border_rounded,
                    color:
                        sel ? AppTheme.primaryYellow : AppTheme.textSecondary,
                    size: 32,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // ── Aberto agora ─────────────────────────────────────────────
          Row(children: [
            const Text('Aberto agora',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const Spacer(),
            Switch(
              value: isOpenNow ?? false,
              activeThumbColor: AppTheme.primaryYellow,
              activeTrackColor: AppTheme.primaryYellow.withValues(alpha: 0.5),
              onChanged: (v) => onIsOpenNowChanged(v ? true : null),
            ),
          ]),
          const Divider(height: 16),

          // ── Geolocalização ───────────────────────────────────────────
          _SectionLabel('Distância (Salvador, BA)'),
          if (locationPermissionDenied)
            const Text(
              'Permissão de localização negada. Ative nas configurações do dispositivo.',
              style: TextStyle(fontSize: 12, color: AppTheme.error),
            )
          else if (locationLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Obtendo localização…',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
            )
          else if (!hasLocation)
            OutlinedButton.icon(
              onPressed: onRequestLocation,
              icon: const Icon(Icons.my_location, size: 16),
              label: const Text('Usar minha localização'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0)),
            )
          else ...[
            Row(children: [
              const Icon(Icons.location_on,
                  size: 16, color: AppTheme.primaryYellowDark),
              const SizedBox(width: 4),
              Text(
                  'Localização obtida  •  Raio: ${radius.toStringAsFixed(0)} km',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
              const Spacer(),
              TextButton(
                  onPressed: onClearLocation,
                  style: TextButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                  child: const Text('Remover', style: TextStyle(fontSize: 12))),
            ]),
            Slider(
              value: radius,
              min: 1,
              max: 30,
              divisions: 29,
              label: '${radius.toStringAsFixed(0)} km',
              activeColor: AppTheme.primaryYellow,
              onChanged: onRadiusChanged,
            ),
          ],
          const Divider(height: 16),

          // ── Ordenar por ──────────────────────────────────────────────
          _SectionLabel('Ordenar por'),
          Wrap(
            spacing: 8,
            children: sortOptions.map((opt) {
              final sel = sortBy == opt.$1;
              return ChoiceChip(
                label: Text(opt.$2,
                    style: TextStyle(
                        fontSize: 12,
                        color: sel
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary)),
                selected: sel,
                selectedColor: AppTheme.primaryYellow,
                backgroundColor: AppTheme.background,
                side: BorderSide.none,
                onSelected: (_) => onSortByChanged(opt.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Actions ──────────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                child: const Text('Limpar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
                child: const Text('Aplicar filtros'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary)),
      );
}

class _NumberField extends StatelessWidget {
  final String label;
  final double? value;
  final ValueChanged<double?> onChanged;
  const _NumberField(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value?.toStringAsFixed(0),
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.background,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        isDense: true,
      ),
      onChanged: (v) => onChanged(double.tryParse(v)),
    );
  }
}

// ── Location denied banner ────────────────────────────────────────────────────

class _LocationDeniedBanner extends StatelessWidget {
  const _LocationDeniedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF3E0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(children: [
        Icon(Icons.location_off, size: 16, color: Color(0xFFE65100)),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Permissão de localização negada. Ative nas configurações para filtrar por distância.',
            style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
          ),
        ),
      ]),
    );
  }
}

// ── Search result card ────────────────────────────────────────────────────────

class _SearchResultCard extends StatelessWidget {
  final RestaurantSearchResultModel result;
  final VoidCallback onTap;
  const _SearchResultCard({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final asModel = RestaurantModel(
      id: result.id,
      ownerUserId: result.ownerUserId,
      name: result.name,
      description: result.description,
      address: result.address,
      city: result.city,
      latitude: result.latitude,
      longitude: result.longitude,
      category: result.category,
      logoUrl: result.logoUrl,
      coverUrl: result.coverUrl,
      instagramUrl: result.instagramUrl,
      isActive: result.isActive,
      openingHours: result.openingHours,
      dishCount: result.dishCount,
      createdAt: result.createdAt,
    );

    return Stack(
      children: [
        RestaurantCard(restaurant: asModel, onTap: onTap),
        Positioned(
          top: 14,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (result.averageRating > 0)
                _Badge(
                  icon: Icons.star_rounded,
                  iconColor: AppTheme.primaryYellow,
                  label: result.averageRating.toStringAsFixed(1),
                ),
              if (result.distanceKm != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _Badge(
                    icon: Icons.near_me,
                    iconColor: const Color(0xFF1565C0),
                    label: result.distanceKm! < 1
                        ? '${(result.distanceKm! * 1000).round()} m'
                        : '${result.distanceKm!.toStringAsFixed(1)} km',
                  ),
                ),
              if (result.minDishPrice != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _Badge(
                    icon: Icons.attach_money,
                    iconColor: AppTheme.success,
                    label:
                        'a partir de R\$ ${result.minDishPrice!.toStringAsFixed(0)}',
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _OpenBadge(isOpen: result.isCurrentlyOpen),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _Badge(
      {required this.icon, required this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x18000000), blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
      ]),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  final bool isOpen;
  const _OpenBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          isOpen ? Icons.check_circle_outline : Icons.schedule,
          size: 11,
          color: isOpen ? AppTheme.success : AppTheme.error,
        ),
        const SizedBox(width: 3),
        Text(
          isOpen ? 'Aberto' : 'Fechado',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isOpen ? AppTheme.success : AppTheme.error),
        ),
      ]),
    );
  }
}
