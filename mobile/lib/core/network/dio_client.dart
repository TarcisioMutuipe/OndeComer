import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(_RetryInterceptor(dio));
  dio.interceptors.add(_AuthInterceptor(dio, storage));

  return dio;
});

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio, this._storage);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
        if (refreshToken == null) {
          _isRefreshing = false;
          return handler.next(err);
        }

        final response = await _dio.post(
          ApiConstants.refresh,
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Authorization': null}),
        );

        final newToken = response.data['accessToken'] as String;
        final newRefresh = response.data['refreshToken'] as String;
        await _storage.write(key: StorageKeys.accessToken, value: newToken);
        await _storage.write(key: StorageKeys.refreshToken, value: newRefresh);

        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';
        final retryResponse = await _dio.fetch(opts);
        _isRefreshing = false;
        return handler.resolve(retryResponse);
      } catch (_) {
        _isRefreshing = false;
        await _storage.deleteAll();
      }
    }
    handler.next(err);
  }
}

/// Interceptor que faz retry automático em erros de conexão e timeout.
class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 2);

  _RetryInterceptor(this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isRetryable = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;

    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

    if (isRetryable && retryCount < _maxRetries) {
      await Future.delayed(_retryDelay * (retryCount + 1));
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      try {
        final response = await _dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        // Falhou novamente, segue para o próximo handler
      }
    }
    handler.next(err);
  }
}

/// Converte erros do Dio em mensagens amigáveis para o usuário.
String friendlyErrorMessage(dynamic error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'O servidor demorou para responder. Verifique sua conexão e tente novamente.';
      case DioExceptionType.connectionError:
        return 'Não foi possível conectar ao servidor. Verifique se a API está no ar.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) return 'Sessão expirada. Faça login novamente.';
        if (statusCode == 403) return 'Você não tem permissão para esta ação.';
        if (statusCode == 404) return 'Recurso não encontrado.';
        if (statusCode == 409) return 'Conflito: este recurso já existe.';
        if (statusCode != null && statusCode >= 500) {
          return 'Erro interno do servidor. Tente novamente em instantes.';
        }
        return error.response?.data?['message']?.toString() ??
            'Erro inesperado. Tente novamente.';
      case DioExceptionType.cancel:
        return 'Requisição cancelada.';
      default:
        return 'Erro de conexão. Verifique sua internet e tente novamente.';
    }
  }
  final msg = error.toString();
  if (msg.contains('SocketException') || msg.contains('Connection refused')) {
    return 'Não foi possível conectar ao servidor.';
  }
  return 'Ocorreu um erro inesperado. Tente novamente.';
}

// ignore: non_constant_identifier_names
void debugPrint(String message) {
  // ignore: avoid_print
  print('[DIO] $message');
}
