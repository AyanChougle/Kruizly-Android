import '''package:dio/dio.dart''';
import '''../config/app_config.dart''';
import '''../errors/app_exceptions.dart''';
import '''auth_interceptor.dart''';

class ApiClient {
  late final Dio _dio;
  Dio get dio => _dio;

  ApiClient({String? baseUrl}) {
    String resolvedBaseUrl = baseUrl ?? AppConfig.apiBaseUrl;
    if (resolvedBaseUrl.endsWith('/api') || resolvedBaseUrl.endsWith('/api/')) {
      resolvedBaseUrl = resolvedBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
    }
    _dio = Dio(
      BaseOptions(
        baseUrl: resolvedBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          '''Content-Type''': '''application/json''',
          '''Accept''': '''application/json''',
        },
      ),
    );

    _dio.interceptors.add(AuthInterceptor());
  }

  String _resolvePath(String path) {
    var p = path.trim();
    if (!p.startsWith('/')) {
      p = '/$p';
    }
    if (!p.startsWith('/api/') && p != '/api') {
      p = '/api$p';
    }
    return p;
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        _resolvePath(path),
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        _resolvePath(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        _resolvePath(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        _resolvePath(path),
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<dynamic> uploadFile(
    String path, {
    required FormData formData,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onProgress,
        options: Options(
          contentType: '''multipart/form-data''',
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  AppException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    final resp = e.response;
    if (resp != null) {
      final data = resp.data;
      String message = '''Server request failed.''';
      if (data is Map && (data['''error'''] != null || data['''message'''] != null)) {
        message = (data['''error'''] ?? data['''message''']).toString();
      }
      return ServerException(message, statusCode: resp.statusCode, details: data);
    }

    return AppException(e.message ?? '''Unknown network error''');
  }
}
