import 'package:dio/dio.dart';

import 'backend_config.dart';

class ApiClient {
  ApiClient({required this.getAccessToken}) {
    dio = Dio(
      BaseOptions(
        baseUrl: BackendConfig.baseUrl(),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  late final Dio dio;
  final Future<String?> Function() getAccessToken;
}
