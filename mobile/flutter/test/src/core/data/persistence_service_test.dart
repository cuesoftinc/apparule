import 'package:apparule/src/core/data/persistence_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PersistenceService', () {
    test('session tokens go through secure storage only (§9)', () async {
      final storage = _MockSecureStorage();
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'token-1');
      when(
        () => storage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      final service = PersistenceService(secureStorage: storage);
      await service.writeSessionToken('token-1');
      expect(await service.readSessionToken(), 'token-1');
      await service.clearSessionToken();

      verify(
        () => storage.write(key: 'session_token', value: 'token-1'),
      ).called(1);
      verify(() => storage.delete(key: 'session_token')).called(1);
    });

    test('theme preference is the one SharedPreferences concern', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final service = PersistenceService(secureStorage: _MockSecureStorage());

      expect(await service.readThemeMode(), isNull);
      await service.writeThemeMode('dark');
      expect(await service.readThemeMode(), 'dark');
    });
  });
}
