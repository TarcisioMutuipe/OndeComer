import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

final searchDatasourceProvider =
    Provider((ref) => SearchDatasource(ref.watch(dioProvider)));

class SearchDatasource {
  final Dio _dio;
  SearchDatasource(this._dio);

  Future<Map<String, dynamic>> search({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    double? lat,
    double? lng,
    double? radius,
    bool? isOpenNow,
    String sortBy = 'relevance',
    String sortOrder = 'asc',
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      if (query != null && query.isNotEmpty) 'query': query,
      if (category != null && category.isNotEmpty) 'category': category,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (minRating != null) 'minRating': minRating,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (radius != null) 'radius': radius,
      if (isOpenNow != null) 'isOpenNow': isOpenNow,
    };
    final response = await _dio.get(
      ApiConstants.restaurantsSearch,
      queryParameters: params,
    );
    return response.data as Map<String, dynamic>;
  }
}
