import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(secureStorageProvider),
  );
});

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final FlutterSecureStorage _storage;

  AuthRepositoryImpl(this._remote, this._storage);

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    final user = await _remote.loginWithEmail(email, password);
    await _saveTokens(user);
    return user;
  }

  @override
  Future<UserModel> loginWithGoogle(String idToken) async {
    final user = await _remote.loginWithGoogle(idToken);
    await _saveTokens(user);
    return user;
  }

  @override
  Future<UserModel> register(
      String name, String email, String password, String profileType) async {
    final user = await _remote.register(name, email, password, profileType);
    await _saveTokens(user);
    return user;
  }

  @override
  Future<UserModel> refreshToken(String refreshToken) async {
    final user = await _remote.refreshToken(refreshToken);
    await _saveTokens(user);
    return user;
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } finally {
      await _storage.deleteAll();
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    if (token == null) return null;
    try {
      return await _remote.getProfile();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserModel> updateProfile(String name, String? avatarUrl) async {
    return _remote.updateProfile(name, avatarUrl);
  }

  Future<void> _saveTokens(UserModel user) async {
    await _storage.write(key: StorageKeys.accessToken, value: user.accessToken);
    await _storage.write(
        key: StorageKeys.refreshToken, value: user.refreshToken);
  }
}
