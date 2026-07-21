import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_client.g.dart';

/// The single configured Dio client (mobile-implementation.md §6) — the
/// data-layer shape is real from day one, but nothing calls it until the
/// API wave (§1 phase 4) introduces the `*Remote` repositories.
@Riverpod(keepAlive: true)
Dio apiClient(Ref ref) {
  final dio = Dio(
    BaseOptions(
      // The base URL arrives via --dart-define-from-file=env/<flavor>.json
      // (Doppler-generated, §2) together with the API wave.
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
}
