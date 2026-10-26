import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/dish_model.dart';
import '../viewmodels/restaurant_viewmodel.dart';
import '../viewmodels/dish_viewmodel.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';

class RestaurantDashboardScreen extends ConsumerStatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  ConsumerState<RestaurantDashboardScreen> createState() =>
      _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState
    extends ConsumerState<RestaurantDashboardScreen> {
  int _currentPage = 0;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    print('[Dashboard] _loadData START');
    await ref.read(restaurantViewModelProvider.notifier).loadMyRestaurant();
    final restaurant = ref.read(restaurantViewModelProvider).restaurant;
    print('[Dashboard] restaurant loaded: ${restaurant?.id}');
    if (restaurant != null) {
      print('[Dashboard] calling loadDishes for ${restaurant.id}');
      await ref
          .read(dishViewModelProvider(restaurant.id).notifier)
          .loadDishes();
      print('[Dashboard] loadDishes completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    final state = ref.watch(restaurantViewModelProvider);
    final restaurant = state.restaurant;

    if (state.isLoading && restaurant == null) {
      return MainScaffold(
          child:
              const Scaffold(body: Center(child: CircularProgressIndicator())));
    }

    if (restaurant == null) {
      return MainScaffold(
        child: Scaffold(
          appBar: AppBar(title: const Text('Área do Estabelecimento')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryYellow.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_outlined,
                      size: 64, color: AppTheme.primaryYellowDark),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Faça Parte do Guia Gastronômico de Salvador',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aumente o movimento do seu salão físico sem pagar comissões abusivas por pedido.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),

                // Vantagens B2B
                _b2bBenefitItem(
                  icon: Icons.money_off_outlined,
                  title: 'Taxa Zero no Salão',
                  subtitle: 'Não cobramos porcentagem sobre o consumo dos seus clientes no restaurante.',
                ),
                const SizedBox(height: 12),
                _b2bBenefitItem(
                  icon: Icons.qr_code_2_outlined,
                  title: 'Cardápio Digital & QR Code de Mesa',
                  subtitle: 'Gere QR Codes prontos para imprimir e colocar nas mesas do seu estabelecimento.',
                ),
                const SizedBox(height: 12),
                _b2bBenefitItem(
                  icon: Icons.flash_on_outlined,
                  title: 'Promoções para Dias Fracos',
                  subtitle: 'Lance ofertas pontuais de terça a quinta para atrair novos clientes aos horários ociosos.',
                ),
                const SizedBox(height: 12),
                _b2bBenefitItem(
                  icon: Icons.loyalty_outlined,
                  title: 'Fidelização & Check-in Oficial',
                  subtitle: 'Recompense clientes fiéis e receba avaliações autênticas da gastronomia da casa.',
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/restaurant/form'),
                    icon: const Icon(Icons.add_business_outlined),
                    label: const Text(
                      'Cadastrar Meu Restaurante Grátis',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: AppTheme.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    }

    final dishState = ref.watch(dishViewModelProvider(restaurant.id));

    return MainScaffold(
        child: Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Métricas',
            onPressed: () =>
                context.push('/restaurant/metrics/${restaurant.id}'),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                context.push('/restaurant/form', extra: restaurant),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(restaurantViewModelProvider.notifier)
              .loadMyRestaurant();
          await ref
              .read(dishViewModelProvider(restaurant.id).notifier)
              .loadDishes();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Restaurant Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (restaurant.logoUrl != null)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            restaurant.logoUrl!,
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.restaurant,
                                size: 48,
                                color: Colors.grey),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(restaurant.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    if (restaurant.description != null) ...[
                      const SizedBox(height: 4),
                      Text(restaurant.description!,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Expanded(child: Text(restaurant.address)),
                    ]),
                    Row(children: [
                      const Icon(Icons.category, size: 16),
                      const SizedBox(width: 4),
                      Text(restaurant.category),
                    ]),
                    Row(children: [
                      Icon(
                        restaurant.isActive ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: restaurant.isActive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(restaurant.isActive ? 'Ativo' : 'Inativo'),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Promotions Section
            OutlinedButton.icon(
              onPressed: () =>
                  context.push(AppRoutes.ownerPromotions, extra: restaurant.id),
              icon: const Icon(Icons.local_offer_outlined),
              label: const Text('Gerenciar Promoções'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.finalizePromotionTicket),
              icon: const Icon(Icons.qr_code_scanner_outlined),
              label: const Text('Finalizar ticket de promoção'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),
            // Moderation Section
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.moderation),
              icon: const Icon(Icons.gavel),
              label: const Text('Moderação (avaliações e comentários)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 16),
            // Menu Section — Grid paginada
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cardápio',
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () => context
                      .push('/restaurant/${restaurant.id}/dish/form')
                      .then((_) {
                    ref
                        .read(dishViewModelProvider(restaurant.id).notifier)
                        .loadDishes();
                  }),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Prato'),
                ),
              ],
            ),
            if (dishState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (dishState.error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(dishState.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref
                            .read(dishViewModelProvider(restaurant.id).notifier)
                            .loadDishes(),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
            else if (dishState.dishes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Nenhum prato cadastrado ainda.'),
                ),
              )
            else
              _buildDishGrid(context, dishState.dishes, restaurant.id),
          ],
        ),
      ),
    )); // MainScaffold + Scaffold
  }

  /// Ordena: ativos primeiro, depois inativos. Pagina em blocos de 10.
  Widget _buildDishGrid(
      BuildContext context, List<DishModel> allDishes, String restaurantId) {
    // Ordenar: ativos primeiro, inativos no final
    final sorted = List<DishModel>.from(allDishes)
      ..sort((a, b) {
        if (a.isActive == b.isActive) return a.name.compareTo(b.name);
        return a.isActive ? -1 : 1;
      });

    final totalPages = (sorted.length / _pageSize).ceil();
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, sorted.length);
    final pageDishes = sorted.sublist(start, end);

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: pageDishes.length,
          itemBuilder: (context, i) =>
              _buildDishCard(context, pageDishes[i], restaurantId),
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                'Página ${_currentPage + 1} de $totalPages',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              IconButton(
                onPressed: _currentPage < totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDishCard(
      BuildContext context, DishModel dish, String restaurantId) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: dish.isActive ? 2 : 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context
            .push('/restaurant/$restaurantId/dish/form', extra: dish)
            .then((_) {
          ref.read(dishViewModelProvider(restaurantId).notifier).loadDishes();
        }),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem ou placeholder
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  dish.imageUrl != null
                      ? Image.network(
                          dish.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.fastfood,
                                size: 40, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.fastfood,
                              size: 40, color: Colors.grey),
                        ),
                  // Badge ativo/inativo
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: dish.isActive
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        dish.isActive ? 'Ativo' : 'Inativo',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dish.category,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'R\$ ${dish.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.green),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => context
                                  .push('/restaurant/$restaurantId/dish/form',
                                      extra: dish)
                                  .then((_) => ref
                                      .read(dishViewModelProvider(restaurantId)
                                          .notifier)
                                      .loadDishes()),
                              child: const Icon(Icons.edit,
                                  size: 18, color: Colors.blue),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _confirmDelete(
                                  context, restaurantId, dish.id),
                              child: const Icon(Icons.delete,
                                  size: 18, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
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

  void _confirmDelete(
      BuildContext context, String restaurantId, String dishId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir prato?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(dishViewModelProvider(restaurantId).notifier)
                  .deleteDish(dishId);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _b2bBenefitItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryYellowDark, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
