import 'package:apparule/src/core/data/persistence_service.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_client.g.dart';

/// The single configured Dio client (mobile-implementation.md §6) — the
/// auth repository and the `*Remote` repositories share it.
///
/// `API_URL` is the origin serving `/api/v1`, injected through
/// `--dart-define-from-file=env/<flavor>.json` (§2). Every request carries
/// `Authorization: Bearer <token>` while a session token is at rest.
@Riverpod(keepAlive: true)
Dio apiClient(Ref ref) {
  final persistence = ref.watch(persistenceServiceProvider);
  final dio = Dio(
    BaseOptions(
      // ignore: avoid_redundant_argument_values, unset API_URL is the empty default.
      baseUrl: const String.fromEnvironment('API_URL'),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await persistence.readSessionToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
  ref.onDispose(dio.close);
  return dio;
}
