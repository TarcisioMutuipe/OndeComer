import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});

class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource(this._dio);

  /// Converte AuthResponse { accessToken, refreshToken, expiresAt, user: {...} }
  /// para o formato plano esperado pelo UserModel
  UserModel _parseAuthResponse(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? json;
    return UserModel.fromJson({
      ...user,
      'accessToken': json['accessToken'] ?? '',
      'refreshToken': json['refreshToken'] ?? '',
    });
  }

  Future<UserModel> loginWithEmail(String email, String password) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    return _parseAuthResponse(response.data as Map<String, dynamic>);
  }

  Future<UserModel> loginWithGoogle(String idToken) async {
    final response = await _dio.post(
      ApiConstants.google,
      data: {'idToken': idToken},
    );
    return _parseAuthResponse(response.data as Map<String, dynamic>);
  }

  Future<UserModel> register(
      String name, String email, String password, String profileType) async {
    final username = email
        .split('@')
        .first
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    final response = await _dio.post(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        'username': username,
        'password': password,
        'profileType': profileType,
      },
    );
    return _parseAuthResponse(response.data as Map<String, dynamic>);
  }

  Future<UserModel> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      ApiConstants.refresh,
      data: {'refreshToken': refreshToken},
    );
    return _parseAuthResponse(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _dio.post(ApiConstants.logout);
  }

  Future<void> deleteMyAccount() async {
    await _dio.delete(ApiConstants.accountDeleteMe);
  }

  Future<String> exportMyData({String format = 'json'}) async {
    final response = await _dio.get(
      ApiConstants.accountExportMe,
      queryParameters: {'format': format},
      options: Options(responseType: ResponseType.plain),
    );
    return response.data.toString();
  }

  Future<UserModel> getProfile() async {
    final response = await _dio.get(ApiConstants.me);
    // GET /me retorna UserDto diretamente (sem accessToken/refreshToken)
    // precisamos manter os tokens atuais armazenados
    return UserModel.fromJson({
      ...response.data as Map<String, dynamic>,
      'accessToken': '',
      'refreshToken': '',
    });
  }

  Future<UserModel> updateProfile(String name, String? avatarUrl) async {
    final response = await _dio.put(
      ApiConstants.me,
      data: {
        'name': name,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
    );
    return UserModel.fromJson({
      ...response.data as Map<String, dynamic>,
      'accessToken': '',
      'refreshToken': '',
    });
  }
}
