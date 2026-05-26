import 'package:dio/dio.dart';

import '../constants/app_config.dart';
import 'auth_storage.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
      validateStatus: (status) => status != null && status < 500,
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          if (response.statusCode == 401) {
            await AuthStorage.clear();
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          final status = e.response?.statusCode;
          if (status == 401) {
            await AuthStorage.clear();
          }
          return handler.next(e);
        },
      ),
    );

  static String _url(String path) {
    // Dio will handle slashes; keep this for readability.
    if (!path.startsWith('/')) return '/$path';
    return path;
  }

  static Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? query}) {
    return dio.get<T>(_url(path), queryParameters: query);
  }

  static Future<Response<T>> post<T>(
    String path, {
    Map<String, dynamic>? query,
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return dio.post<T>(
      _url(path),
      queryParameters: query,
      data: data,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  static Future<Response<T>> patch<T>(
    String path, {
    Map<String, dynamic>? query,
    required dynamic data,
  }) {
    return dio.patch<T>(_url(path), queryParameters: query, data: data);
  }

  static Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? query,
  }) {
    return dio.delete<T>(_url(path), queryParameters: query);
  }
}
