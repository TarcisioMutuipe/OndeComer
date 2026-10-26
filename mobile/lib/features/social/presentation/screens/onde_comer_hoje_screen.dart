import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../restaurant/presentation/viewmodels/restaurant_list_viewmodel.dart';
import '../../../restaurant/data/models/restaurant_model.dart';

class OndeComerHojeScreen extends ConsumerStatefulWidget {
  const OndeComerHojeScreen({super.key});

  @override
  ConsumerState<OndeComerHojeScreen> createState() =>
      _OndeComerHojeScreenState();
}

class _OndeComerHojeScreenState extends ConsumerState<OndeComerHojeScreen> {
  String _selectedVibe = 'Rio Vermelho';
  final Set<String> _selectedRestaurantIds = {};

  static const _vibes = [
    ('Rio Vermelho', 'Rio Vermelho (Agito & Boemia)', Icons.nightlife),
    ('Pelourinho', 'Pelourinho & Carmo (História & Charme)', Icons.account_balance),
    ('Barra', 'Barra & Ondina (Praia & Pôr do Sol)', Icons.wb_sunny),
    ('Pituba', 'Pituba & Itaigara (Botecos & Gourmet)', Icons.restaurant),
    ('Ribeira', 'Ribeira (Moqueca & Sorvete)', Icons.sailing),
    ('Itapuã', 'Itapuã (Mar & Tradição)', Icons.beach_access),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectForVibe(_selectedVibe);
    });
  }

  void _autoSelectForVibe(String vibe) {
    final restaurants = ref.read(restaurantListViewModelProvider).restaurants;
    final matching = restaurants.where((r) {
      final addr = r.address.toLowerCase();
      final cat = r.category.toLowerCase();
      final v = vibe.toLowerCase();
      return addr.contains(v) || cat.contains(v);
    }).toList();

    setState(() {
      _selectedRestaurantIds.clear();
      final list = matching.isNotEmpty ? matching : restaurants;
      for (final r in list.take(3)) {
        _selectedRestaurantIds.add(r.id);
      }
    });
  }

  void _randomPick() {
    final restaurants = ref.read(restaurantListViewModelProvider).restaurants;
    if (restaurants.isEmpty) return;

    final shuffled = List<RestaurantModel>.from(restaurants)..shuffle();
    setState(() {
      _selectedRestaurantIds.clear();
      for (final r in shuffled.take(3)) {
        _selectedRestaurantIds.add(r.id);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('3 opções sorteadas aleatoriamente por Salvador! 🎲'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleRestaurant(String id) {
    setState(() {
      if (_selectedRestaurantIds.contains(id)) {
        _selectedRestaurantIds.remove(id);
      } else {
        if (_selectedRestaurantIds.length >= 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você pode selecionar no máximo 4 opções para a enquete.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        _selectedRestaurantIds.add(id);
      }
    });
  }

  List<RestaurantModel> _getSelectedRestaurants() {
    final all = ref.read(restaurantListViewModelProvider).restaurants;
    return all.where((r) => _selectedRestaurantIds.contains(r.id)).toList();
  }

  void _copyWhatsAppPoll() {
    final selected = _getSelectedRestaurants();
    if (selected.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos 2 restaurantes para a enquete!'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final emojis = ['1️⃣', '2️⃣', '3️⃣', '4️⃣'];
    final buffer = StringBuffer();
    buffer.writeln('🍽️ *Onde vamos comer hoje em Salvador?* 🌊');
    buffer.writeln('Galera, ajudem a decidir nosso rolê:');
    buffer.writeln();

    for (var i = 0; i < selected.length; i++) {
      final r = selected[i];
      final emoji = i < emojis.length ? emojis[i] : '${i + 1}️⃣';
      buffer.writeln('$emoji *${r.name}*');
      buffer.writeln('   📍 ${r.address}');
      if (r.category.isNotEmpty) {
        buffer.writeln('   🍴 Culinária: ${r.category}');
      }
      buffer.writeln();
    }

    buffer.writeln('👉 *Responda com o número da sua escolha!*');
    buffer.writeln('🍻 Quem perder a votação paga a primeira rodada!');
    buffer.writeln('📲 Veja cardápios e avaliações no app *Onde Comer em Salvador*');

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enquete copiada com sucesso! Cole no WhatsApp da galera. 📲'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _spinDecisionWheel() {
    final selected = _getSelectedRestaurants();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione ao menos 1 restaurante para sortear!'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RoletaDialog(
        restaurants: selected,
        onFinished: (winner) {
          Navigator.of(ctx).pop();
          _showWinnerDialog(winner);
        },
      ),
    );
  }

  void _showWinnerDialog(RestaurantModel winner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🎉 ', style: TextStyle(fontSize: 24)),
            Expanded(
              child: Text(
                'Decisão Tomada!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A Roleta Soteropolitana escolheu o destino de hoje:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryYellow),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    winner.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          winner.address,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  if (winner.category.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Cozinha: ${winner.category}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ninguém discute mais, o rolê tá fechado! Partiu comer! 🛵💨',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              foregroundColor: AppTheme.textPrimary,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/restaurant/${winner.id}');
            },
            child: const Text('Ver Cardápio'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restaurantListViewModelProvider);
    final selectedCount = _selectedRestaurantIds.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Onde Comer Hoje? 🎲'),
        actions: [
          IconButton(
            tooltip: 'Opções Aleatórias',
            icon: const Icon(Icons.shuffle),
            onPressed: _randomPick,
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Hero Banner ───────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.how_to_vote, color: AppTheme.primaryYellow, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Enquete com a Galera',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Escolha até 4 opções, gere uma enquete formatada para o WhatsApp ou rode a Roleta da Decisão quando ninguém entrar em acordo!',
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _vibes.map((v) {
                            final isSel = _selectedVibe == v.$1;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                avatar: Icon(
                                  v.$3,
                                  size: 15,
                                  color: isSel ? AppTheme.textPrimary : Colors.white70,
                                ),
                                label: Text(v.$1),
                                selected: isSel,
                                selectedColor: AppTheme.primaryYellow,
                                backgroundColor: const Color(0xFF334155),
                                labelStyle: TextStyle(
                                  color: isSel ? AppTheme.textPrimary : Colors.white,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                                onSelected: (_) {
                                  setState(() => _selectedVibe = v.$1);
                                  _autoSelectForVibe(v.$1);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Restaurant Selector List ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Candidatos Selecionados ($selectedCount/4)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: _randomPick,
                        icon: const Icon(Icons.casino_outlined, size: 16),
                        label: const Text('Sortear 3', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: state.restaurants.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final r = state.restaurants[index];
                      final isSelected = _selectedRestaurantIds.contains(r.id);

                      return InkWell(
                        onTap: () => _toggleRestaurant(r.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryYellow : AppTheme.divider,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: AppTheme.primaryYellowDark,
                                onChanged: (_) => _toggleRestaurant(r.id),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r.address,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.background,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            r.category,
                                            style: const TextStyle(
                                                fontSize: 10, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Action Bar ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 10,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: Color(0xFF0F172A)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.casino, size: 18),
                            label: const Text(
                              'Roleta 🎯',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: _spinDecisionWheel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text(
                              'Copiar Enquete Zap',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: _copyWhatsAppPoll,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RoletaDialog extends StatefulWidget {
  final List<RestaurantModel> restaurants;
  final ValueChanged<RestaurantModel> onFinished;

  const _RoletaDialog({
    required this.restaurants,
    required this.onFinished,
  });

  @override
  State<_RoletaDialog> createState() => _RoletaDialogState();
}

class _RoletaDialogState extends State<_RoletaDialog> {
  int _currentIndex = 0;
  Timer? _timer;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    _startSpin();
  }

  void _startSpin() {
    final random = Random();
    final targetTicks = 20 + random.nextInt(10); // 20-30 spins

    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      _ticks++;
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.restaurants.length;
      });

      if (_ticks >= targetTicks) {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          widget.onFinished(widget.restaurants[_currentIndex]);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.restaurants[_currentIndex];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Center(
        child: Text(
          '🎯 Girando a Roleta...',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryYellow, width: 2),
            ),
            child: Column(
              children: [
                const Icon(Icons.restaurant_menu,
                    size: 40, color: AppTheme.primaryYellowDark),
                const SizedBox(height: 12),
                Text(
                  current.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  current.address,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const LinearProgressIndicator(color: AppTheme.primaryYellow),
          const SizedBox(height: 8),
          const Text(
            'Decidindo o rolê com a sabedoria da Bahia...',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

