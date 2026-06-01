import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(ref.watch(authRepositoryProvider));
});

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _google {
    _googleSignIn ??= GoogleSignIn(scopes: ['email', 'profile']);
    return _googleSignIn!;
  }

  AuthViewModel(this._repo) : super(const AuthState()) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repo.getCurrentUser();
      state = state.copyWith(
        status: user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        user: user,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.loginWithEmail(email, password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: _mapError(e),
        isLoading: false,
      );
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final googleUser = await _google.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final auth = await googleUser.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('Google idToken not available');

      final user = await _repo.loginWithGoogle(idToken);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: _mapError(e),
        isLoading: false,
      );
    }
  }

  Future<void> register(
      String name, String email, String password, String profileType) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.register(name, email, password, profileType);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: _mapError(e),
        isLoading: false,
      );
    }
  }

  Future<void> updateProfile(String name, String? avatarUrl) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.updateProfile(name, avatarUrl);
      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: _mapError(e),
        isLoading: false,
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.logout();
      await _google.signOut();
    } finally {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  String _mapError(Object e) {
    // Verificar primeiro o tipo do DioException (mais preciso)
    if (e is DioException) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) return 'E-mail ou senha incorretos.';
      if (statusCode == 409) return 'Este e-mail já está cadastrado.';

      // Timeout ou servidor indisponível — NÃO é falta de internet
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'O servidor demorou para responder. Tente novamente.';
      }

      // Erro de conexão: pode ser servidor down OU sem internet
      if (e.type == DioExceptionType.connectionError) {
        final msg = e.message ?? '';
        // SocketException e Failed host lookup indicam VERDADEIRA falta de internet
        if (msg.contains('SocketException') ||
            msg.contains('Failed host lookup') ||
            msg.contains('Network is unreachable')) {
          return 'Sem conexão com a internet.';
        }
        // Nos demais casos (ex.: XMLHttpRequest error no web = servidor indisponível)
        return 'Não foi possível conectar ao servidor. Verifique se a API está no ar.';
      }
    }

    // Fallback para erros sem tipo Dio (ex.: exceções manuais)
    final msg = e.toString();
    if (msg.contains('401') || msg.contains('credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (msg.contains('409') || msg.contains('already')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (msg.contains('SocketException') || msg.contains('Failed host lookup')) {
      return 'Sem conexão com a internet.';
    }
    return 'Algo deu errado. Tente novamente.';
  }
}
