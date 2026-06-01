import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dio_client.dart';

class ImageUploadService {
  final Dio _dio;

  ImageUploadService(this._dio);

  /// Uploads [xFile] to the API and returns the public URL.
  /// [entityType] should be "Restaurant", "Dish" or "User".
  Future<String> uploadImage(
    XFile xFile, {
    String entityType = 'General',
    String? entityId,
  }) async {
    final bytes = await xFile.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: xFile.name,
      ),
    });

    final queryParams = <String, dynamic>{'entityType': entityType};
    if (entityId != null) queryParams['entityId'] = entityId;

    final response = await _dio.post(
      '/api/v1/images/upload',
      data: formData,
      queryParameters: queryParams,
    );

    return response.data['url'] as String;
  }
}

final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  final dio = ref.watch(dioProvider);
  return ImageUploadService(dio);
});
