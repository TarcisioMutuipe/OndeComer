import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../viewmodels/restaurant_list_viewmodel.dart';
import '../widgets/restaurant_card.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class RestaurantListScreen extends ConsumerStatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  ConsumerState<RestaurantListScreen> createState() =>
      _RestaurantListScreenState();
}

class _RestaurantListScreenState extends ConsumerState<RestaurantListScreen> {
  final _scrollController = ScrollController();
  String _selectedHub = 'Todos';

  static const _salvadorHubs = [
    ('Todos', 'Todos', Icons.place_outlined),
    ('Rio Vermelho', 'Rio Vermelho', Icons.nightlife_outlined),
    ('Pelourinho', 'Pelourinho & Carmo', Icons.account_balance_outlined),
    ('Barra', 'Barra & Ondina', Icons.beach_access_outlined),
    ('Pituba', 'Pituba & Itaigara', Icons.restaurant_outlined),
    ('Ribeira', 'Ribeira', Icons.icecream_outlined),
    ('Itapuã', 'Itapuã', Icons.wb_sunny_outlined),
  ];

  static const _curatedRoutes = [
    (
      '🌅 Pôr do Sol na Baía',
      'Restaurantes com vista deslumbrante e gastronomia litorânea',
      'Barra',
      Color(0xFFD97706),
      Color(0xFFF59E0B),
    ),
    (
      '🌶️ Circuito do Dendê',
      'Casas tradicionais de moqueca, acarajé e tempero baiano',
      'Rio Vermelho',
      Color(0xFFDC2626),
      Color(0xFFF87171),
    ),
    (
      '☕ Charme no Centro Histórico',
      'Cafés, bistrôs e arte no Pelourinho e Santo Antônio Além do Carmo',
      'Pelourinho',
      Color(0xFF7C3AED),
      Color(0xFFA78BFA),
    ),
    (
      '🍦 Sabores da Cidade Baixa',
      'Frutos do mar e sorvetes icônicos na orla da Ribeira',
      'Ribeira',
      Color(0xFF0D9488),
      Color(0xFF2DD4BF),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(restaurantListViewModelProvider.notifier).load(refresh: true);
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(restaurantListViewModelProvider.notifier).load();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onSelectHub(String hub) {
    setState(() => _selectedHub = hub);
    ref
        .read(restaurantListViewModelProvider.notifier)
        .setSearch(hub == 'Todos' ? null : hub);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restaurantListViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final isAdmin = authState.user?.profileType == 'Admin';
    final isRestaurant = authState.user?.profileType == 'Restaurant';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: Image.asset('assets/images/logo.png',
            height: 32,
            errorBuilder: (_, __, ___) => const Text('Onde Comer',
                style: TextStyle(fontWeight: FontWeight.bold))),
        actions: [
          if (isAdmin) ...[
            IconButton(
              tooltip: 'Painel do Administrador',
              icon: const Icon(Icons.admin_panel_settings, color: Colors.indigo),
              onPressed: () => context.push(AppRoutes.admin),
            ),
          ] else if (isRestaurant) ...[
            IconButton(
              tooltip: 'Meu Painel',
              icon: const Icon(Icons.storefront, color: AppTheme.primaryYellowDark),
              onPressed: () => context.go('/restaurant/panel'),
            ),
          ] else ...[
            IconButton(
              tooltip: 'Meus Selos & Fidelidade',
              icon: const Icon(Icons.stars_rounded, color: AppTheme.primaryYellowDark),
              onPressed: () => context.push('/loyalty'),
            ),
          ],
          IconButton(
            tooltip: 'Meus Favoritos',
            icon: const Icon(Icons.favorite_outline, color: AppTheme.textPrimary),
            onPressed: () => context.push('/favorites'),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: _SearchBar(
                    onSearch: (q) {
                      setState(() => _selectedHub = 'Todos');
                      ref
                          .read(restaurantListViewModelProvider.notifier)
                          .setSearch(q);
                    }),
              ),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _salvadorHubs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final hub = _salvadorHubs[index];
                    final isSelected = _selectedHub == hub.$1;
                    return ChoiceChip(
                      selected: isSelected,
                      avatar: Icon(
                        hub.$3,
                        size: 16,
                        color: isSelected
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                      label: Text(
                        hub.$2,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
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
                      onSelected: (_) => _onSelectHub(hub.$1),
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
            .read(restaurantListViewModelProvider.notifier)
            .load(refresh: true),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(RestaurantListState state) {
    if (state.isLoading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) => const RestaurantSkeletonCard(),
      );
    }
    if (state.error != null && state.restaurants.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off, size: 48, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text(state.error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref
                .read(restaurantListViewModelProvider.notifier)
                .load(refresh: true),
            child: const Text('Tentar novamente'),
          ),
        ]),
      );
    }
    if (state.restaurants.isEmpty) {
      return const Center(child: Text('Nenhum restaurante encontrado.'));
    }
    final showCuratedHeader = _selectedHub == 'Todos';
    final headerOffset = showCuratedHeader ? 1 : 0;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.restaurants.length +
          (state.isLoadingMore ? 2 : 0) +
          headerOffset,
      itemBuilder: (context, i) {
        if (showCuratedHeader && i == 0) {
          return _buildCuratedHeader(context);
        }
        final restaurantIndex = i - headerOffset;
        if (restaurantIndex >= state.restaurants.length) {
          return const RestaurantSkeletonCard();
        }
        return RestaurantCard(
          restaurant: state.restaurants[restaurantIndex],
          onTap: () =>
              context.push('/restaurant/${state.restaurants[restaurantIndex].id}'),
        );
      },
    );
  }

  Widget _buildCuratedHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Passaporte Gastronômico Banner
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryYellow.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.explore_outlined,
                      color: AppTheme.primaryYellow, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Passaporte Salvador',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Faça check-in nos restaurantes e colecione selos por Salvador!',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: AppTheme.textPrimary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => context.push('/loyalty'),
                  child: const Text('Ver Selos',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),

        // Curated Routes Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text(
            'Roteiros & Experiências de Salvador',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _curatedRoutes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final r = _curatedRoutes[index];
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _onSelectHub(r.$3),
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [r.$4, r.$5],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: r.$4.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        r.$1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            'Explorar Polo',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward,
                              size: 11, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Onde Comer Hoje Banner
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push(AppRoutes.ondeComerHoje),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryYellow.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryYellow.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.casino,
                        color: AppTheme.primaryYellowDark, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Indeciso no rolê? "Onde Comer Hoje?" 🎲',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Crie enquetes para o WhatsApp ou gire a Roleta da Decisão!',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text(
            'Todos os Restaurantes',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _SearchBar extends StatefulWidget {
  final ValueChanged<String?> onSearch;
  const _SearchBar({required this.onSearch});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onSubmitted: widget.onSearch,
      decoration: InputDecoration(
        hintText: 'Buscar restaurantes em Salvador…',
        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _ctrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _ctrl.clear();
                  widget.onSearch(null);
                  setState(() {});
                })
            : null,
        filled: true,
        fillColor: AppTheme.background,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (v) => setState(() {}),
    );
  }
}
