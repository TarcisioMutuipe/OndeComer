import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/restaurant_search_result_model.dart';
import '../../../restaurant/presentation/widgets/restaurant_open_status_badge.dart';

class SalvadorRadarView extends StatelessWidget {
  final List<RestaurantSearchResultModel> results;
  final double? userLat;
  final double? userLng;
  final ValueChanged<RestaurantSearchResultModel> onSelectRestaurant;
  final ValueChanged<String> onSelectCircuit;

  const SalvadorRadarView({
    super.key,
    required this.results,
    this.userLat,
    this.userLng,
    required this.onSelectRestaurant,
    required this.onSelectCircuit,
  });

  @override
  Widget build(BuildContext context) {
    // Distribute results into distance brackets
    final walkDistance = results.where((r) => (r.distanceKm ?? 999) <= 2.0).toList();
    final shortDrive = results.where((r) {
      final d = r.distanceKm ?? 999;
      return d > 2.0 && d <= 5.0;
    }).toList();
    final mediumDrive = results.where((r) {
      final d = r.distanceKm ?? 999;
      return d > 5.0 && d <= 12.0;
    }).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Banner ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.radar, color: AppTheme.primaryYellow, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Radar Salvador & Baía',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            userLat != null
                                ? 'Localização ativa • Ordenado por proximidade'
                                : 'Referência: Centro Gastronômico de Salvador',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Concentric Radar Rings Graphic
                SizedBox(
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(260, 160),
                        painter: _RadarGridPainter(),
                      ),
                      // Center indicator
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryYellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryYellow.withValues(alpha: 0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_pin_circle, color: Colors.black87, size: 22),
                      ),
                      // Distance indicators around
                      Positioned(
                        top: 8,
                        child: _RadarBadge(
                          label: '< 2 km (A pé)',
                          count: walkDistance.length,
                          color: Colors.lightGreenAccent,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 60,
                        child: _RadarBadge(
                          label: '2-5 km (Uber rápido)',
                          count: shortDrive.length,
                          color: AppTheme.primaryYellow,
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        child: _RadarBadge(
                          label: '5-12 km (Circuito)',
                          count: mediumDrive.length,
                          color: Colors.lightBlueAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Circuitos Gastronômicos de Salvador ────────────────────
          const Text(
            'Circuitos Gastronômicos de Salvador',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Explore as quatro grandes regiões culinárias da capital baiana:',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _CircuitTile(
                title: 'Orla Atlântica',
                sub: 'Barra, Rio Vermelho, Pituba',
                icon: Icons.beach_access,
                color: const Color(0xFF0077B6),
                onTap: () => onSelectCircuit('Rio Vermelho'),
              ),
              _CircuitTile(
                title: 'Histórico & Baía',
                sub: 'Pelourinho, Santo Antônio',
                icon: Icons.account_balance,
                color: const Color(0xFFD90429),
                onTap: () => onSelectCircuit('Pelourinho'),
              ),
              _CircuitTile(
                title: 'Cidade Baixa',
                sub: 'Ribeira, Bonfim, Humaitá',
                icon: Icons.sailing,
                color: const Color(0xFF2A9D8F),
                onTap: () => onSelectCircuit('Ribeira'),
              ),
              _CircuitTile(
                title: 'Litoral Norte',
                sub: 'Itapuã, Stella Maris',
                icon: Icons.wb_sunny,
                color: const Color(0xFFF4A261),
                onTap: () => onSelectCircuit('Itapuã'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Lista de Restaurantes por Proximidade ──────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mais Próximos do Seu Radar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              Text(
                '${results.length} no radar',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (results.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.location_off, size: 40, color: AppTheme.textSecondary),
                  SizedBox(height: 8),
                  Text('Nenhum restaurante encontrado no raio atual.', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            )
          else
            ...results.take(15).map((r) => _RadarRestaurantCard(
                  restaurant: r,
                  onTap: () => onSelectRestaurant(r),
                )),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Radar Painter ────────────────────────────────────────────────────────────

class _RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paintRing = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final paintCross = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw concentric circles
    canvas.drawCircle(center, 30, paintRing);
    canvas.drawCircle(center, 55, paintRing);
    canvas.drawCircle(center, 80, paintRing);

    // Cross axes
    canvas.drawLine(Offset(center.dx - 90, center.dy), Offset(center.dx + 90, center.dy), paintCross);
    canvas.drawLine(Offset(center.dx, center.dy - 70), Offset(center.dx, center.dy + 70), paintCross);

    // Simulated blips
    final blipPaint = Paint()
      ..color = AppTheme.primaryYellow.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(center.dx + 40, center.dy - 35), 4, blipPaint);
    canvas.drawCircle(Offset(center.dx - 45, center.dy + 25), 3.5, blipPaint);
    canvas.drawCircle(Offset(center.dx + 65, center.dy + 20), 4.5, blipPaint);
    canvas.drawCircle(Offset(center.dx - 20, center.dy - 40), 3, blipPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RadarBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _RadarBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$label: $count',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Circuit Tile ─────────────────────────────────────────────────────────────

class _CircuitTile extends StatelessWidget {
  final String title;
  final String sub;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircuitTile({
    required this.title,
    required this.sub,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
            boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                sub,
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Restaurant Card on Radar ─────────────────────────────────────────────────

class _RadarRestaurantCard extends StatelessWidget {
  final RestaurantSearchResultModel restaurant;
  final VoidCallback onTap;

  const _RadarRestaurantCard({
    required this.restaurant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dist = restaurant.distanceKm;
    final distLabel = dist != null
        ? (dist < 1.0 ? '${(dist * 1000).toInt()}m' : '${dist.toStringAsFixed(1)}km')
        : null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      color: AppTheme.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Photo or initial
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: restaurant.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: restaurant.coverUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _buildFallbackIcon(),
                        )
                      : _buildFallbackIcon(),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      restaurant.address,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (restaurant.averageRating > 0) ...[
                          const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            restaurant.averageRating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          restaurant.category,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Badges Column (Open status + Distance)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RestaurantOpenStatusBadge(
                    overrideIsOpen: restaurant.isCurrentlyOpen,
                    openingHours: restaurant.openingHours,
                    compact: true,
                  ),
                  if (distLabel != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me, size: 12, color: AppTheme.primaryYellowDark),
                          const SizedBox(width: 3),
                          Text(
                            distLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryYellowDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: AppTheme.background,
      child: const Icon(Icons.restaurant, color: AppTheme.textSecondary, size: 28),
    );
  }
}

