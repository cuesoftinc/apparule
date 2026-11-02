import 'dart:typed_data';

import 'package:apparule/src/core/data/api_client.dart';
import 'package:apparule/src/core/data/persistence_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPersistenceService extends Mock implements PersistenceService {}

class _CapturingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString('', 204);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _MockPersistenceService persistence;
  late ProviderContainer container;

  setUp(() {
    persistence = _MockPersistenceService();
    container = ProviderContainer(
      overrides: [persistenceServiceProvider.overrideWithValue(persistence)],
    );
    addTearDown(container.dispose);
  });

  test('apiClient provides a single configured Dio', () {
    final dio = container.read(apiClientProvider);
    expect(dio.options.connectTimeout, const Duration(seconds: 10));
    expect(dio.options.receiveTimeout, const Duration(seconds: 20));
    // keepAlive: repeated reads return the same client.
    expect(container.read(apiClientProvider), same(dio));
  });

  test('attaches the stored session token as a Bearer', () async {
    when(() => persistence.readSessionToken()).thenAnswer((_) async => 'tok-1');
    final adapter = _CapturingAdapter();
    final dio = container.read(apiClientProvider)..httpClientAdapter = adapter;

    await dio.get<void>('https://api.example.com/api/v1/me');

    expect(adapter.requests.single.headers['Authorization'], 'Bearer tok-1');
  });

  test('sends no Authorization header without a token', () async {
    when(() => persistence.readSessionToken()).thenAnswer((_) async => null);
    final adapter = _CapturingAdapter();
    final dio = container.read(apiClientProvider)..httpClientAdapter = adapter;

    await dio.get<void>('https://api.example.com/api/v1/me');

    expect(adapter.requests.single.headers, isNot(contains('Authorization')));
  });
}
