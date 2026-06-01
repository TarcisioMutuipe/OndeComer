import 'package:onde_comer_em_salvador/features/auth/data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> loginWithGoogle(String idToken);
  Future<UserModel> loginWithEmail(String email, String password);
  Future<UserModel> register(
      String name, String email, String password, String profileType);
  Future<UserModel> refreshToken(String refreshToken);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<UserModel> updateProfile(String name, String? avatarUrl);
}
