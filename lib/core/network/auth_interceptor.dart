import '''package:dio/dio.dart''';
import '''package:firebase_auth/firebase_auth.dart''';

class AuthInterceptor extends Interceptor {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final token = await user.getIdToken();
        if (token != null && token.isNotEmpty) {
          options.headers['''Authorization'''] = '''Bearer $token''';
          options.headers['''X-Authorization'''] = '''Bearer $token''';
          options.headers['''X-Firebase-Token'''] = token;
        }
      } catch (e) {
        // Fallback: Proceed without token if refresh fails
      }
    }
    options.headers['''Accept'''] = '''application/json''';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final user = _auth.currentUser;
      if (user != null) {
        try {
          // Force refresh Firebase token
          final freshToken = await user.getIdToken(true);
          if (freshToken != null && freshToken.isNotEmpty) {
            final opts = err.requestOptions;
            opts.headers['''Authorization'''] = '''Bearer $freshToken''';
            opts.headers['''X-Authorization'''] = '''Bearer $freshToken''';
            opts.headers['''X-Firebase-Token'''] = freshToken;

            final dio = Dio();
            final cloneReq = await dio.fetch(opts);
            return handler.resolve(cloneReq);
          }
        } catch (_) {}
      }
    }
    handler.next(err);
  }
}
