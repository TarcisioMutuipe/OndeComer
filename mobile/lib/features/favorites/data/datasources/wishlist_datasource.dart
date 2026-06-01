import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/wishlist_model.dart';
import '../models/wishlist_item_model.dart';

class WishlistDatasource {
  final Dio _dio;
  WishlistDatasource(this._dio);

  Future<List<WishlistModel>> getAll() async {
    final response = await _dio.get(ApiConstants.wishlistsBase);
    return (response.data as List)
        .map((e) => WishlistModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WishlistModel> getById(String id) async {
    final response = await _dio.get(ApiConstants.wishlistById(id));
    return WishlistModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WishlistModel> getPublic(String shareToken) async {
    final response = await _dio.get(ApiConstants.wishlistPublic(shareToken));
    return WishlistModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WishlistModel> create({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    final response = await _dio.post(
      ApiConstants.wishlistsBase,
      data: {
        'name': name,
        if (description != null) 'description': description,
        'isPublic': isPublic,
      },
    );
    return WishlistModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WishlistModel> update(
    String id, {
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    final response = await _dio.put(
      ApiConstants.wishlistById(id),
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (isPublic != null) 'isPublic': isPublic,
      },
    );
    return WishlistModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete(ApiConstants.wishlistById(id));
  }

  Future<Map<String, String>> generateShareToken(String id) async {
    final response = await _dio.post(ApiConstants.wishlistShare(id));
    return {
      'shareToken': response.data['shareToken'] as String,
      'shareUrl': response.data['shareUrl'] as String,
    };
  }

  Future<WishlistItemModel> addItem(
    String wishlistId, {
    String? restaurantId,
    String? dishId,
    String? note,
  }) async {
    final response = await _dio.post(
      ApiConstants.wishlistItems(wishlistId),
      data: {
        if (restaurantId != null) 'restaurantId': restaurantId,
        if (dishId != null) 'dishId': dishId,
        if (note != null) 'note': note,
      },
    );
    return WishlistItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> removeItem(String itemId) async {
    await _dio.delete(ApiConstants.wishlistItemById(itemId));
  }
}
