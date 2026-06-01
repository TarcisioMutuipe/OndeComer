import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/wishlist_datasource.dart';
import '../../data/models/wishlist_model.dart';
import '../../data/models/wishlist_item_model.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final wishlistDatasourceProvider = Provider<WishlistDatasource>(
  (ref) => WishlistDatasource(ref.watch(dioProvider)),
);

final wishlistViewModelProvider =
    StateNotifierProvider<WishlistViewModel, WishlistState>(
  (ref) => WishlistViewModel(ref.watch(wishlistDatasourceProvider)),
);

// ---------------------------------------------------------------------------
// Estado
// ---------------------------------------------------------------------------

class WishlistState {
  final List<WishlistModel> lists;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final WishlistModel? viewingPublic;

  const WishlistState({
    this.lists = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.viewingPublic,
  });

  WishlistState copyWith({
    List<WishlistModel>? lists,
    bool? isLoading,
    bool? isSaving,
    String? error,
    WishlistModel? viewingPublic,
  }) =>
      WishlistState(
        lists: lists ?? this.lists,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: error,
        viewingPublic: viewingPublic ?? this.viewingPublic,
      );
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class WishlistViewModel extends StateNotifier<WishlistState> {
  final WishlistDatasource _ds;

  WishlistViewModel(this._ds) : super(const WishlistState());

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final lists = await _ds.getAll();
      state = state.copyWith(lists: lists, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<WishlistModel?> loadPublic(String shareToken) async {
    state = state.copyWith(isLoading: true);
    try {
      final wishlist = await _ds.getPublic(shareToken);
      state = state.copyWith(isLoading: false, viewingPublic: wishlist);
      return wishlist;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<WishlistModel?> create({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    state = state.copyWith(isSaving: true);
    try {
      final created = await _ds.create(
        name: name,
        description: description,
        isPublic: isPublic,
      );
      state = state.copyWith(
        lists: [...state.lists, created],
        isSaving: false,
      );
      return created;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }

  Future<bool> update(
    String id, {
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    state = state.copyWith(isSaving: true);
    try {
      final updated = await _ds.update(id,
          name: name, description: description, isPublic: isPublic);
      state = state.copyWith(
        lists: state.lists.map((l) => l.id == id ? updated : l).toList(),
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _ds.delete(id);
      state = state.copyWith(
        lists: state.lists.where((l) => l.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<String?> generateShareToken(String id) async {
    try {
      final result = await _ds.generateShareToken(id);
      final token = result['shareToken']!;
      state = state.copyWith(
        lists: state.lists.map((l) {
          if (l.id != id) return l;
          return WishlistModel(
            id: l.id,
            userId: l.userId,
            name: l.name,
            description: l.description,
            isPublic: true,
            shareToken: token,
            shareUrl: result['shareUrl'],
            itemCount: l.itemCount,
            items: l.items,
            createdAt: l.createdAt,
            updatedAt: l.updatedAt,
          );
        }).toList(),
      );
      return token;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<WishlistItemModel?> addItem(
    String wishlistId, {
    String? restaurantId,
    String? dishId,
    String? note,
  }) async {
    try {
      final item = await _ds.addItem(
        wishlistId,
        restaurantId: restaurantId,
        dishId: dishId,
        note: note,
      );
      state = state.copyWith(
        lists: state.lists.map((l) {
          if (l.id != wishlistId) return l;
          return WishlistModel(
            id: l.id,
            userId: l.userId,
            name: l.name,
            description: l.description,
            isPublic: l.isPublic,
            shareToken: l.shareToken,
            shareUrl: l.shareUrl,
            itemCount: l.itemCount + 1,
            items: [...l.items, item],
            createdAt: l.createdAt,
            updatedAt: l.updatedAt,
          );
        }).toList(),
      );
      return item;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> removeItem(String wishlistId, String itemId) async {
    try {
      await _ds.removeItem(itemId);
      state = state.copyWith(
        lists: state.lists.map((l) {
          if (l.id != wishlistId) return l;
          final newItems = l.items.where((i) => i.id != itemId).toList();
          return WishlistModel(
            id: l.id,
            userId: l.userId,
            name: l.name,
            description: l.description,
            isPublic: l.isPublic,
            shareToken: l.shareToken,
            shareUrl: l.shareUrl,
            itemCount: newItems.length,
            items: newItems,
            createdAt: l.createdAt,
            updatedAt: l.updatedAt,
          );
        }).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}
