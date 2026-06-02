import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api.dart';

class ApiService {
  ApiService._() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        debugPrint('→ ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (err, handler) {
        debugPrint('✗ ${err.response?.statusCode} ${err.requestOptions.uri}: ${err.message}');
        handler.next(err);
      },
    ));
  }

  static final ApiService instance = ApiService._();

  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'algovest_access_token';
  static const _refreshKey = 'algovest_refresh_token';

  final _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  Future<void> storeTokens(String access, String refresh) async {
    await _storage.write(key: _tokenKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? params}) {
    return _dio.get(path, queryParameters: params);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }
}