import 'package:apparule/src/core/data/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('apiClient provides a single configured Dio', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dio = container.read(apiClientProvider);
    expect(dio.options.connectTimeout, const Duration(seconds: 10));
    expect(dio.options.receiveTimeout, const Duration(seconds: 20));
    // keepAlive: repeated reads return the same client.
    expect(container.read(apiClientProvider), same(dio));
  });
}
