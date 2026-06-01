import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/wishlist_model.dart';
import '../viewmodels/wishlist_viewmodel.dart';

class MinhasListasScreen extends ConsumerStatefulWidget {
  const MinhasListasScreen({super.key});

  @override
  ConsumerState<MinhasListasScreen> createState() => _MinhasListasScreenState();
}

class _MinhasListasScreenState extends ConsumerState<MinhasListasScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(wishlistViewModelProvider.notifier).loadAll());
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isPublic = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('Nova lista'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome da lista *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Lista pública'),
                subtitle: const Text('Qualquer pessoa com o link pode ver'),
                value: isPublic,
                onChanged: (v) => setLocalState(() => isPublic = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await ref.read(wishlistViewModelProvider.notifier).create(
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty
                          ? null
                          : descCtrl.text.trim(),
                      isPublic: isPublic,
                    );
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(WishlistModel list) {
    final nameCtrl = TextEditingController(text: list.name);
    final descCtrl = TextEditingController(text: list.description ?? '');
    bool isPublic = list.isPublic;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('Editar lista'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome da lista',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Lista pública'),
                value: isPublic,
                onChanged: (v) => setLocalState(() => isPublic = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(wishlistViewModelProvider.notifier).update(
                      list.id,
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty
                          ? null
                          : descCtrl.text.trim(),
                      isPublic: isPublic,
                    );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(WishlistModel list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir lista'),
        content: Text('Deseja excluir a lista "${list.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(wishlistViewModelProvider.notifier).delete(list.id);
    }
  }

  Future<void> _share(WishlistModel list) async {
    final vm = ref.read(wishlistViewModelProvider.notifier);
    final token = list.shareToken ?? await vm.generateShareToken(list.id);
    if (token != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link de compartilhamento: /wishlists/public/$token'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wishlistViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Listas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nova lista'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.lists.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Nenhuma lista criada',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                      SizedBox(height: 8),
                      Text(
                        'Crie listas para organizar seus favoritos',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: state.lists.length,
                  itemBuilder: (context, i) {
                    final list = state.lists[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              list.isPublic ? Colors.green : Colors.grey,
                          child: Icon(
                            list.isPublic ? Icons.public : Icons.lock_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(list.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${list.itemCount} ${list.itemCount == 1 ? 'item' : 'itens'}'
                          '${list.description != null ? ' · ${list.description}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => context.push('/wishlists/${list.id}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            switch (action) {
                              case 'edit':
                                _showEditDialog(list);
                              case 'share':
                                _share(list);
                              case 'delete':
                                _confirmDelete(list);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Editar')),
                            PopupMenuItem(
                                value: 'share', child: Text('Compartilhar')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Excluir',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
