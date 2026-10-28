import 'dart:async';
import 'dart:convert';

import 'package:apparule/src/core/data/persistence_service.dart';
import 'package:apparule/src/features/auth/data/auth_repository_api.dart';
import 'package:apparule/src/features/auth/domain/auth_exception.dart';
import 'package:apparule/src/features/auth/domain/auth_session.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// The §9 SSO handoff tested at the repository seam: a recording Dio
// adapter and an injected web-auth function keep it pure Dart, no
// platform channels (mobile-implementation.md §8).

class _MockPersistenceService extends Mock implements PersistenceService {}

typedef _Reply = ResponseBody Function(RequestOptions options, String body);

class _Adapter implements HttpClientAdapter {
  _Adapter(this._reply);

  final _Reply _reply;
  final List<({RequestOptions options, String body})> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[
      if (requestStream != null)
        for (final chunk in await requestStream.toList()) ...chunk,
    ];
    final body = utf8.decode(bytes);
    requests.add((options: options, body: body));
    return _reply(options, body);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

const _account = {
  'id': 'acct-1',
  'email': 'kiki.adeyemi@example.com',
  'display_name': 'Kiki Adeyemi',
  'avatar_url': 'https://cdn.example.com/kiki.png',
};

const _expectedSession = AuthSession(
  uid: 'acct-1',
  email: 'kiki.adeyemi@example.com',
  displayName: 'Kiki Adeyemi',
  photoUrl: 'https://cdn.example.com/kiki.png',
);

String _s256(String verifier) => base64Url
    .encode(sha256.convert(ascii.encode(verifier)).bytes)
    .replaceAll('=', '');

void main() {
  late _MockPersistenceService persistence;
  late _Adapter adapter;
  late Dio dio;
  late List<String> authenticatedUrls;
  late Future<String> Function() onAuthenticate;

  AuthRepositoryApi build() => AuthRepositoryApi(
    dio: dio,
    persistenceService: persistence,
    webAuthenticate: ({required url, required callbackUrlScheme}) {
      expect(callbackUrlScheme, 'apparule');
      authenticatedUrls.add(url);
      return onAuthenticate();
    },
  );

  void useReply(_Reply reply) {
    adapter = _Adapter(reply);
    dio.httpClientAdapter = adapter;
  }

  setUp(() {
    persistence = _MockPersistenceService();
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    authenticatedUrls = [];
    onAuthenticate = () async => 'apparule://app/auth/callback?handoff=h-1';
    when(() => persistence.writeSessionToken(any())).thenAnswer((_) async {});
    when(() => persistence.clearSessionToken()).thenAnswer((_) async {});
    when(() => persistence.readSessionToken()).thenAnswer((_) async => null);
    useReply((options, body) {
      return switch (options.path) {
        '/api/v1/auth/sso/exchange' => _json(200, {
          'access_token': 'tok-1',
          'expires_in': 900,
        }),
        '/api/v1/me' => _json(200, _account),
        _ => _json(404, {}),
      };
    });
  });

  group('signInWithGoogle', () {
    test('runs the handoff and binds the verifier to the challenge', () async {
      final repository = build();
      final changes = <AuthSession?>[];
      final sub = repository.sessionChanges().listen(changes.add);
      addTearDown(sub.cancel);

      final session = await repository.signInWithGoogle();
      await Future<void>.delayed(Duration.zero);

      expect(session, _expectedSession);
      expect(changes, [_expectedSession]);

      final start = Uri.parse(authenticatedUrls.single);
      expect(start.origin, 'https://api.example.com');
      expect(start.path, '/api/v1/auth/sso/google');
      expect(start.queryParameters['return_to'], 'apparule://app');

      final exchange = adapter.requests.firstWhere(
        (r) => r.options.path == '/api/v1/auth/sso/exchange',
      );
      expect(exchange.options.method, 'POST');
      expect(exchange.options.headers['Content-Type'], contains('json'));
      final posted = jsonDecode(exchange.body) as Map<String, dynamic>;
      final verifier = posted['verifier'] as String;
      expect(posted['handoff'], 'h-1');
      expect(verifier, matches(RegExp(r'^[A-Za-z0-9\-._~]{43,128}$')));
      expect(start.queryParameters['cv'], _s256(verifier));

      verify(() => persistence.writeSessionToken('tok-1')).called(1);
      expect(adapter.requests.last.options.path, '/api/v1/me');
    });

    test('a dismissed browser tab is canceled', () async {
      onAuthenticate = () async =>
          throw PlatformException(code: 'CANCELED', message: 'User canceled');

      await expectLater(
        build().signInWithGoogle(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            AuthErrorCode.canceled,
          ),
        ),
      );
      expect(adapter.requests, isEmpty);
      verifyNever(() => persistence.writeSessionToken(any()));
    });

    test('error=access_denied from the API is canceled', () async {
      onAuthenticate = () async =>
          'apparule://app/signin?error=access_denied&message=Denied';

      await expectLater(
        build().signInWithGoogle(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            AuthErrorCode.canceled,
          ),
        ),
      );
      expect(adapter.requests, isEmpty);
    });

    test('any other callback error is unknown with its description', () async {
      onAuthenticate = () async =>
          'apparule://app/signin?error=sso_failed&error_description=Try%20again';

      await expectLater(
        build().signInWithGoogle(),
        throwsA(
          isA<AuthException>()
              .having((e) => e.code, 'code', AuthErrorCode.unknown)
              .having((e) => e.message, 'message', 'Try again'),
        ),
      );
    });

    test('a callback with no handoff is unknown', () async {
      onAuthenticate = () async => 'apparule://app/auth/callback';

      await expectLater(
        build().signInWithGoogle(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            AuthErrorCode.unknown,
          ),
        ),
      );
    });

    test(
      'exchange 401 handoff_invalid is unknown and stores nothing',
      () async {
        useReply((options, body) {
          return _json(401, {
            'error': {'code': 'handoff_invalid', 'message': 'Expired'},
          });
        });

        await expectLater(
          build().signInWithGoogle(),
          throwsA(
            isA<AuthException>()
                .having((e) => e.code, 'code', AuthErrorCode.unknown)
                .having(
                  (e) => e.message,
                  'message',
                  contains('handoff_invalid'),
                ),
          ),
        );
        verifyNever(() => persistence.writeSessionToken(any()));
      },
    );

    test('a connection failure maps to network', () async {
      useReply((options, body) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        );
      });

      await expectLater(
        build().signInWithGoogle(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            AuthErrorCode.network,
          ),
        ),
      );
    });

    test('a failed session read after exchange clears the token', () async {
      useReply((options, body) {
        return options.path == '/api/v1/auth/sso/exchange'
            ? _json(200, {'access_token': 'tok-1', 'expires_in': 900})
            : _json(401, {});
      });

      await expectLater(
        build().signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
      verify(() => persistence.clearSessionToken()).called(1);
    });
  });

  group('restoreSession', () {
    test('a valid token restores the session', () async {
      when(
        () => persistence.readSessionToken(),
      ).thenAnswer((_) async => 'tok-1');

      expect(await build().restoreSession(), _expectedSession);
      expect(adapter.requests.single.options.path, '/api/v1/me');
      verifyNever(() => persistence.clearSessionToken());
    });

    test('no stored token is signed out without a request', () async {
      expect(await build().restoreSession(), isNull);
      expect(adapter.requests, isEmpty);
    });

    test('401 clears the token and returns null', () async {
      when(
        () => persistence.readSessionToken(),
      ).thenAnswer((_) async => 'stale');
      useReply((options, body) => _json(401, {}));

      expect(await build().restoreSession(), isNull);
      verify(() => persistence.clearSessionToken()).called(1);
    });

    test('an unreachable API returns null and keeps the token', () async {
      when(
        () => persistence.readSessionToken(),
      ).thenAnswer((_) async => 'tok-1');
      useReply((options, body) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        );
      });

      expect(await build().restoreSession(), isNull);
      verifyNever(() => persistence.clearSessionToken());
    });
  });

  group('signOut', () {
    test('posts logout, clears the token and emits signed out', () async {
      useReply((options, body) => ResponseBody.fromString('', 204));
      final repository = build();
      final changes = <AuthSession?>[];
      final sub = repository.sessionChanges().listen(changes.add);
      addTearDown(sub.cancel);

      await repository.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(adapter.requests.single.options.path, '/api/v1/auth/logout');
      expect(adapter.requests.single.options.method, 'POST');
      verify(() => persistence.clearSessionToken()).called(1);
      expect(changes, [null]);
    });

    test('clears the token even when logout fails', () async {
      useReply((options, body) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        );
      });

      await build().signOut();

      verify(() => persistence.clearSessionToken()).called(1);
    });
  });
}
