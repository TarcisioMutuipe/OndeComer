import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/youtube_video_player.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/datasources/reservation_remote_datasource.dart';
import '../viewmodels/restaurant_list_viewmodel.dart';
import '../viewmodels/dish_viewmodel.dart';
import '../widgets/restaurant_open_status_badge.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Endereço copiado! Cole no Google Maps, Waze ou Uber.'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareRestaurant(dynamic restaurant) {
    final text = '🍽️ Bora conhecer o ${restaurant.name} em Salvador?\n'
        '📍 ${restaurant.address}\n'
        '⭐ Avaliação: ${restaurant.ratingAverage.toStringAsFixed(1)} estrelas\n\n'
        'Confira o cardápio e promoções no app Onde Comer em Salvador!';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Convite copiado! Cole no WhatsApp ou no grupo.'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _openWhatsAppReservation(dynamic restaurant) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final reservationMsg =
            'Olá! Vi o perfil do ${restaurant.name} no app Onde Comer em Salvador e gostaria de saber sobre reserva de mesa e atendimento para hoje. 🍽️';

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chat_outlined,
                        color: Colors.green.shade700, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Falar com ${restaurant.name}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Text(
                          'Reservas, aniversários e informações',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  reservationMsg,
                  style: const TextStyle(
                      fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar Mensagem Pronta de Reserva',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: reservationMsg));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Mensagem copiada! Cole na conversa do restaurante.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openTableReservationModal(dynamic restaurant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ReservationBookingSheet(restaurant: restaurant),
    );
  }

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
    final restaurantAsync =
        ref.watch(restaurantDetailProvider(widget.restaurantId));
    final dishState = ref.watch(dishViewModelProvider(widget.restaurantId));
    final authUser = ref.watch(authViewModelProvider).user;
    final isAdmin = authUser?.profileType == 'Admin';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: restaurantAsync.when(
        loading: () => _buildSkeleton(),
        error: (e, _) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(e.toString(), textAlign: TextAlign.center),
            TextButton(
                onPressed: () =>
                    ref.refresh(restaurantDetailProvider(widget.restaurantId)),
                child: const Text('Tentar novamente')),
          ]),
        ),
        data: (restaurant) => RefreshIndicator(
          color: AppTheme.primaryYellow,
          onRefresh: () async {
            // ignore: unused_result
            ref.refresh(restaurantDetailProvider(widget.restaurantId));
            await ref
                .read(dishViewModelProvider(widget.restaurantId).notifier)
                .loadDishes(onlyAvailable: true);
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppTheme.white,
                leading: IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.white70,
                    child: Icon(Icons.arrow_back,
                        color: AppTheme.textPrimary, size: 20),
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  if (isAdmin)
                    IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.amber,
                        child: Icon(Icons.shield,
                            color: Colors.black, size: 20),
                      ),
                      tooltip: 'Opções do Administrador',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (ctx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit,
                                      color: Colors.amber),
                                  title: const Text('Editar Restaurante (Admin)'),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    context.push('/restaurant/form?admin=true',
                                        extra: restaurant);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.add_circle,
                                      color: Colors.green),
                                  title: const Text('Publicar Novo Prato (Admin)'),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    context.push(
                                        '/restaurant/${restaurant.id}/dish/form');
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.restaurant_menu,
                                      color: Colors.blue),
                                  title: const Text('Gerenciar Pratos (Admin)'),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    context.push(
                                        '/admin/restaurant/${restaurant.id}/dishes');
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  IconButton(
                    icon: const CircleAvatar(
                      backgroundColor: Colors.white70,
                      child: Icon(Icons.share_outlined,
                          color: AppTheme.textPrimary, size: 20),
                    ),
                    onPressed: () => _shareRestaurant(restaurant),
                    tooltip: 'Compartilhar no WhatsApp ou grupo',
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: restaurant.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: restaurant.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const SkeletonLoader(height: 220, borderRadius: 0),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.divider,
                            child: const Icon(Icons.restaurant,
                                size: 64, color: AppTheme.textSecondary),
                          ),
                        )
                      : Container(
                          color: AppTheme.divider,
                          child: const Icon(Icons.restaurant,
                              size: 64, color: AppTheme.textSecondary),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: AppTheme.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (restaurant.logoUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: restaurant.logoUrl!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.restaurant, size: 56),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(restaurant.name,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(restaurant.category,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary)),
                            if (restaurant.description != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(restaurant.description!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isAdmin)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      border: Border.all(color: Colors.amber.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Painel Admin',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        TextButton.icon(
                          onPressed: () => context.push(
                              '/restaurant/form?admin=true',
                              extra: restaurant),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Editar'),
                        ),
                        TextButton.icon(
                          onPressed: () => context.push(
                              '/restaurant/${restaurant.id}/dish/form'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('+ Prato'),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _copyAddress(restaurant.address),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        const Icon(Icons.location_on,
                            size: 16, color: AppTheme.primaryYellowDark),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(restaurant.address,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500))),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryYellow.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy, size: 12, color: AppTheme.primaryYellowDark),
                              SizedBox(width: 4),
                              Text('Copiar GPS',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryYellowDark)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryYellow,
                          foregroundColor: AppTheme.textPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          minimumSize: const Size(0, 38),
                        ),
                        icon: const Icon(Icons.qr_code_scanner, size: 18),
                        label: const Text('Fazer Check-in & Pontuar',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: () =>
                            context.push('/checkin/${restaurant.id}'),
                      ),
                      if (restaurant.allowsReservations)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            minimumSize: const Size(0, 38),
                          ),
                          icon: const Icon(Icons.table_restaurant, size: 18),
                          label: const Text('Reservar Mesa',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                          onPressed: () => _openTableReservationModal(restaurant),
                        ),
                      if (restaurant.totalTables > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.table_bar_outlined,
                                  size: 15, color: Colors.teal),
                              const SizedBox(width: 4),
                              Text('${restaurant.totalTables} mesas',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      if (restaurant.hasEventSpace)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.celebration_outlined,
                                  size: 15, color: Colors.purple.shade700),
                              const SizedBox(width: 4),
                              Text(
                                  'Espaço p/ eventos${restaurant.eventSpaceCapacity != null ? ' (${restaurant.eventSpaceCapacity} pes.)' : ''}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.purple.shade800,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade800,
                          side: BorderSide(color: Colors.green.shade600),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          minimumSize: const Size(0, 38),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Reservar / WhatsApp',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: () => _openWhatsAppReservation(restaurant),
                      ),
                      if (restaurant.openingHours.isNotEmpty) ...[
                        RestaurantOpenStatusBadge(
                          openingHours: restaurant.openingHours,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time,
                                  size: 15, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(restaurant.openingHours,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                      if (restaurant.instagramUrl != null &&
                          restaurant.instagramUrl!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt_outlined,
                                  size: 15, color: Colors.purple),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.instagramUrl!.contains('/')
                                    ? '@${restaurant.instagramUrl!.split('/').last}'
                                    : '@${restaurant.instagramUrl}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // YouTube Video Section
              if (restaurant.youTubeVideoUrl != null &&
                  restaurant.youTubeVideoUrl!.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Vídeo',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        YouTubeVideoPlayerWidget(
                            videoUrl: restaurant.youTubeVideoUrl!),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: Divider(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Cardápio',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (dishState.isLoading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                      (_, __) => const FeedSkeletonCard(),
                      childCount: 4),
                )
              else if (dishState.dishes.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: Text('Cardápio indisponível no momento.',
                            style: TextStyle(color: AppTheme.textSecondary))),
                  ),
                )
              else
                _DishSliverList(groupedDishes: _groupDishes(dishState.dishes)),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<dynamic>> _groupDishes(List dishes) {
    final map = <String, List<dynamic>>{};
    for (final d in dishes) map.putIfAbsent(d.category, () => []).add(d);
    return map;
  }

  Widget _buildSkeleton() {
    return CustomScrollView(slivers: [
      const SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          flexibleSpace:
              FlexibleSpaceBar(background: RestaurantSkeletonCard())),
      SliverList(
          delegate: SliverChildBuilderDelegate(
              (_, __) => const FeedSkeletonCard(),
              childCount: 6)),
    ]);
  }
}

class _DishSliverList extends StatelessWidget {
  final Map<String, List<dynamic>> groupedDishes;
  const _DishSliverList({required this.groupedDishes});

  @override
  Widget build(BuildContext context) {
    final categories = groupedDishes.keys.toList();
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, i) {
        if (i.isEven) {
          final cat = categories[i ~/ 2];
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(cat,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.textPrimary)),
          );
        }
        final cat = categories[i ~/ 2];
        final dishes = groupedDishes[cat]!;
        return Column(
          children:
              dishes.map<Widget>((dish) => _DishTile(dish: dish)).toList(),
        );
      }, childCount: categories.length * 2),
    );
  }
}

class _DishTile extends StatelessWidget {
  final dynamic dish;
  const _DishTile({required this.dish});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/dish/${dish.id}', extra: dish),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)],
        ),
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dish.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (dish.description != null)
                Text(dish.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text('R\$ ${(dish.price as num).toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppTheme.primaryYellowDark,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
          if (dish.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: dish.imageUrl!,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  memCacheWidth: 200,
                  memCacheHeight: 200,
                  placeholder: (_, __) => const SkeletonLoader(
                      width: 64, height: 64, borderRadius: 8),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.fastfood, size: 40),
                ),
              ),
            ),
        ]),
      ), // GestureDetector
    );
  }
}

class _ReservationBookingSheet extends ConsumerStatefulWidget {
  final dynamic restaurant;
  const _ReservationBookingSheet({required this.restaurant});

  @override
  ConsumerState<_ReservationBookingSheet> createState() =>
      _ReservationBookingSheetState();
}

class _ReservationBookingSheetState extends ConsumerState<_ReservationBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String _selectedTimeSlot = '19:30';
  int _partySize = 2;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  static const List<String> _timeSlots = [
    '11:30', '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00',
    '18:00', '18:30', '19:00', '19:30', '20:00', '20:30', '21:00', '21:30', '22:00', '22:30'
  ];

  @override
  void initState() {
    super.initState();
    final authUser = ref.read(authViewModelProvider).user;
    _nameController = TextEditingController(text: authUser?.name ?? '');
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(reservationRemoteDatasourceProvider).createReservation(
            restaurantId: widget.restaurant.id,
            customerName: _nameController.text.trim(),
            customerPhone: _phoneController.text.trim(),
            reservationDate: _selectedDate,
            timeSlot: _selectedTimeSlot,
            partySize: _partySize,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context); // Close sheet
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Reserva Solicitada!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sua mesa no ${widget.restaurant.name} foi agendada para:'),
                const SizedBox(height: 8),
                Text(
                  '📅 ${DateFormat('dd/MM/yyyy').format(_selectedDate)} às $_selectedTimeSlot\n'
                  '👥 $_partySize pessoas\n'
                  '⏰ Tolerância de até 15 minutos',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text('Você pode acompanhar o status em Minhas Reservas.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fechar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.myReservations);
                },
                child: const Text('Ver Minhas Reservas'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível realizar a reserva: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.table_restaurant,
                        color: Colors.teal.shade700, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reservar Mesa',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          widget.restaurant.name,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tolerance Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.timer_outlined, color: Colors.orange, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tolerância de 15 minutos: Sua mesa será mantida por até 15 minutos após o horário agendado.',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data da Reserva *',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy (EEE)', 'pt_BR').format(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Time Slot and Party Size
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Horário *',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      value: _selectedTimeSlot,
                      items: _timeSlots
                          .map((slot) => DropdownMenuItem(
                                value: slot,
                                child: Text(slot),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTimeSlot = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Pessoas *',
                        prefixIcon: Icon(Icons.people_outline),
                      ),
                      value: _partySize,
                      items: List.generate(15, (i) => i + 1)
                          .map((num) => DropdownMenuItem(
                                value: num,
                                child: Text('$num ${num == 1 ? 'pessoa' : 'pessoas'}'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _partySize = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Name and Phone
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Responsável *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone / WhatsApp *',
                  hintText: '(71) 99999-9999',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o telefone' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                  hintText: 'Ex: mesa externa, comemoração de aniversário...',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSubmitting ? null : _submitReservation,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Confirmar Reserva',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

