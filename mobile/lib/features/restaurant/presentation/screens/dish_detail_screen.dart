import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/reviews/presentation/screens/dish_review_section.dart';
import '../../data/models/dish_model.dart';

class DishDetailScreen extends StatelessWidget {
  final DishModel dish;

  const DishDetailScreen({super.key, required this.dish});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(dish.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Dish image ────────────────────────────────────────────────
            if (dish.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: dish.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  memCacheWidth: 800,
                  placeholder: (_, __) =>
                      const SkeletonLoader(width: double.infinity, height: 200),
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: AppTheme.divider,
                    child: const Center(child: Icon(Icons.fastfood, size: 64)),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // ── Info ──────────────────────────────────────────────────────
            Text(dish.name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'R\$ ${dish.price.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 18,
                  color: AppTheme.primaryYellowDark,
                  fontWeight: FontWeight.bold),
            ),
            if (dish.description != null) ...[
              const SizedBox(height: 8),
              Text(dish.description!,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
            ],

            // ── Rating badge ──────────────────────────────────────────────
            if (dish.ratingAverage > 0) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${dish.ratingAverage.toStringAsFixed(1)} (${dish.ratingCount} avaliações)',
                  style: const TextStyle(fontSize: 13),
                ),
              ]),
            ],

            const SizedBox(height: 24),
            const Divider(),

            // ── Reviews & Comments ────────────────────────────────────────
            DishReviewSection(dishId: dish.id, dishName: dish.name),
          ],
        ),
      ),
    );
  }
}
