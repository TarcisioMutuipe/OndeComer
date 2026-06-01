import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/wishlist_item_model.dart';
import '../viewmodels/wishlist_viewmodel.dart';

class ListaPublicaScreen extends ConsumerStatefulWidget {
  final String shareToken;
  const ListaPublicaScreen({super.key, required this.shareToken});

  @override
  ConsumerState<ListaPublicaScreen> createState() => _ListaPublicaScreenState();
}

class _ListaPublicaScreenState extends ConsumerState<ListaPublicaScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(wishlistViewModelProvider.notifier)
        .loadPublic(widget.shareToken));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wishlistViewModelProvider);
    final wishlist = state.viewingPublic;

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (wishlist == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lista não encontrada')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.link_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Esta lista não existe ou foi removida.',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(wishlist.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: const Text('Pública'),
              avatar: const Icon(Icons.public, size: 16),
              backgroundColor: Colors.green.shade100,
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (wishlist.description != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                wishlist.description!,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              '${wishlist.itemCount} ${wishlist.itemCount == 1 ? 'item' : 'itens'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: wishlist.items.isEmpty
                ? const Center(
                    child: Text(
                      'Esta lista está vazia.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: wishlist.items.length,
                    itemBuilder: (context, i) =>
                        _WishlistItemTile(item: wishlist.items[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _WishlistItemTile extends StatelessWidget {
  final WishlistItemModel item;
  const _WishlistItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isRestaurant = item.restaurantId != null;
    final name = isRestaurant
        ? (item.restaurantName ?? 'Restaurante')
        : (item.dishName ?? 'Prato');
    final imageUrl = isRestaurant ? item.restaurantLogoUrl : item.dishImageUrl;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                ),
              )
            : _placeholder(),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isRestaurant ? 'Restaurante' : 'Prato',
                style: const TextStyle(fontSize: 12)),
            if (item.note != null)
              Text(item.note!,
                  style: const TextStyle(
                      fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.restaurant),
      );
}
