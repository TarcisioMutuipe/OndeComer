import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../models/review_model.dart';
import '../models/comment_model.dart';

class ReviewDatasource {
  final Dio _dio;
  ReviewDatasource(this._dio);

  Future<ReviewModel> submitReview(String dishId, int rating) async {
    final res = await _dio
        .post('/api/v1/dishes/$dishId/review', data: {'rating': rating});
    return ReviewModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CommentModel> submitComment(String dishId, String text) async {
    final res =
        await _dio.post('/api/v1/dishes/$dishId/comment', data: {'text': text});
    return CommentModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<CommentModel>> getApprovedComments(String dishId) async {
    final res = await _dio.get('/api/v1/dishes/$dishId/comments');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CommentModel>> getPendingComments() async {
    final res = await _dio.get('/api/v1/comments/pending');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommentModel> moderateComment(String commentId, String action) async {
    final res = await _dio
        .put('/api/v1/comments/$commentId/moderate', data: {'action': action});
    return CommentModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ReviewModel>> getPendingReviews() async {
    final res = await _dio.get('/api/v1/reviews/pending');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReviewModel> moderateReview(String reviewId, String action) async {
    final res = await _dio
        .put('/api/v1/reviews/$reviewId/moderate', data: {'action': action});
    return ReviewModel.fromJson(res.data as Map<String, dynamic>);
  }
}

final reviewDatasourceProvider = Provider<ReviewDatasource>((ref) {
  return ReviewDatasource(ref.watch(dioProvider));
});
