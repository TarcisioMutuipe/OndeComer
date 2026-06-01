import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/favorite_button.dart';
import '../viewmodels/favorite_viewmodel.dart';

class MinhasFavoritasScreen extends ConsumerStatefulWidget {
  const MinhasFavoritasScreen({super.key});

  @override
  ConsumerState<MinhasFavoritasScreen> createState() =>
      _MinhasFavoritasScreenState();
}

class _MinhasFavoritasScreenState extends ConsumerState<MinhasFavoritasScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(favoriteViewModelProvider.notifier).loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoriteViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Favoritos')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum favorito ainda',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Toque no ♡ em qualquer restaurante ou prato',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  itemBuilder: (context, i) {
                    final fav = state.items[i];
                    final isRestaurant = fav.restaurantId != null;
                    final name = isRestaurant
                        ? (fav.restaurantName ?? 'Restaurante')
                        : (fav.dishName ?? 'Prato');
                    final imageUrl =
                        isRestaurant ? fav.restaurantLogoUrl : fav.dishImageUrl;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 56,
                                    height: 56,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.restaurant),
                                  ),
                                ),
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.restaurant),
                              ),
                        title: Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          isRestaurant ? 'Restaurante' : 'Prato',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: FavoriteButton(
                          restaurantId: isRestaurant ? fav.restaurantId : null,
                          dishId: !isRestaurant ? fav.dishId : null,
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
