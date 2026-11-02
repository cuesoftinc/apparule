import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:apparule/src/core/data/persistence_service.dart';
import 'package:apparule/src/features/auth/data/auth_repository.dart';
import 'package:apparule/src/features/auth/domain/auth_exception.dart';
import 'package:apparule/src/features/auth/domain/auth_session.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

/// Opens [url] in the system browser tab and resolves with the app-link
/// the browser lands on; the `flutter_web_auth_2` seam, swapped in tests.
typedef WebAuthenticate =
    Future<String> Function({
      required String url,
      required String callbackUrlScheme,
    });

Future<String> _defaultWebAuthenticate({
  required String url,
  required String callbackUrlScheme,
}) => FlutterWebAuth2.authenticate(
  url: url,
  callbackUrlScheme: callbackUrlScheme,
);

/// The real §9 implementation: the API's Google SSO handoff, the same
/// method as the web client:
///
///   browser tab on `GET /api/v1/auth/sso/google?return_to=apparule://app&cv=`
///   → `apparule://app/auth/callback?handoff=` → `POST /api/v1/auth/sso/exchange`
///   `{handoff, verifier}` → `access_token` → `GET /api/v1/me`
///
/// The PKCE verifier never leaves the app until the exchange. The access
/// token is sent as a Bearer by the shared Dio client (`apiClient`) and
/// rests in [PersistenceService]'s secure storage, never SharedPreferences
/// (CV-2). Silent restore reads that token back through `GET /api/v1/me`.
class AuthRepositoryApi implements AuthRepository {
  AuthRepositoryApi({
    required this._dio,
    required this._persistenceService,
    this._webAuthenticate = _defaultWebAuthenticate,
    Random? random,
  }) : _random = random ?? Random.secure();

  static const String callbackScheme = 'apparule';
  static const String returnTo = 'apparule://app';

  static const String _startPath = '/api/v1/auth/sso/google';
  static const String _exchangePath = '/api/v1/auth/sso/exchange';
  static const String _mePath = '/api/v1/me';
  static const String _logoutPath = '/api/v1/auth/logout';

  // The API's isPKCEVerifier set; 64 characters sits inside its 43 to 128.
  static const String _verifierAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  static const int _verifierLength = 64;

  final Dio _dio;
  final PersistenceService _persistenceService;
  final WebAuthenticate _webAuthenticate;
  final Random _random;
  final StreamController<AuthSession?> _changes =
      StreamController<AuthSession?>.broadcast();

  @override
  Stream<AuthSession?> sessionChanges() => _changes.stream;

  @override
  Future<AuthSession?> restoreSession() async {
    final token = await _persistenceService.readSessionToken();
    if (token == null || token.isEmpty) return null;
    try {
      return await _fetchSession();
    } on DioException catch (error) {
      // Restore is best-effort by contract: a gone session means signed
      // out, and an unreachable API leaves the token for the next boot.
      if (error.response?.statusCode == 401) {
        await _persistenceService.clearSessionToken();
      }
      return null;
    }
  }

  @override
  Future<AuthSession> signInWithGoogle() async {
    final verifier = _newVerifier();
    final challenge = base64Url
        .encode(sha256.convert(ascii.encode(verifier)).bytes)
        .replaceAll('=', '');
    final callback = await _authenticate(challenge);
    final handoff = _handoffOf(callback);
    final token = await _exchange(handoff, verifier);
    await _persistenceService.writeSessionToken(token);
    final AuthSession session;
    try {
      session = await _fetchSession();
    } on DioException catch (error) {
      await _persistenceService.clearSessionToken();
      throw _mapDio(error);
    }
    _changes.add(session);
    return session;
  }

  @override
  Future<void> signOut() async {
    try {
      await _dio.post<void>(_logoutPath);
    } on DioException {
      // Local sign-out never depends on the network; the token below is
      // the credential and it is purged regardless.
    }
    await _persistenceService.clearSessionToken();
    _changes.add(null);
  }

  Future<String> _authenticate(String challenge) async {
    final start = Uri.parse(
      '${_dio.options.baseUrl.replaceFirst(RegExp(r'/+$'), '')}$_startPath',
    ).replace(queryParameters: {'return_to': returnTo, 'cv': challenge});
    try {
      return await _webAuthenticate(
        url: start.toString(),
        callbackUrlScheme: callbackScheme,
      );
    } on PlatformException catch (error) {
      // flutter_web_auth_2 reports a dismissed tab as CANCELED.
      throw AuthException(
        error.code == 'CANCELED'
            ? AuthErrorCode.canceled
            : AuthErrorCode.unknown,
        error.message,
      );
    }
  }

  String _handoffOf(String callback) {
    final query = Uri.parse(callback).queryParameters;
    final error = query['error'];
    if (error != null) {
      throw AuthException(
        error == 'access_denied'
            ? AuthErrorCode.canceled
            : AuthErrorCode.unknown,
        query['error_description'] ?? query['message'] ?? error,
      );
    }
    final handoff = query['handoff'];
    if (handoff == null || handoff.isEmpty) {
      throw const AuthException(
        AuthErrorCode.unknown,
        'Sign-in returned no handoff',
      );
    }
    return handoff;
  }

  Future<String> _exchange(String handoff, String verifier) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _exchangePath,
        data: {'handoff': handoff, 'verifier': verifier},
        options: Options(contentType: Headers.jsonContentType),
      );
      final token = response.data?['access_token'];
      if (token is! String || token.isEmpty) {
        throw const AuthException(
          AuthErrorCode.unknown,
          'Exchange returned no access token',
        );
      }
      return token;
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  Future<AuthSession> _fetchSession() async {
    final response = await _dio.get<Map<String, dynamic>>(_mePath);
    final data = response.data;
    final id = data?['id'];
    if (data == null || id is! String) {
      throw const AuthException(
        AuthErrorCode.unknown,
        'Session read returned no account',
      );
    }
    return AuthSession(
      uid: id,
      email: data['email'] as String?,
      displayName: data['display_name'] as String?,
      photoUrl: data['avatar_url'] as String?,
    );
  }

  String _newVerifier() => String.fromCharCodes(
    List<int>.generate(
      _verifierLength,
      (_) => _verifierAlphabet.codeUnitAt(
        _random.nextInt(_verifierAlphabet.length),
      ),
    ),
  );

  /// flows/auth.md §4: connectivity failures surface as the offline
  /// notice; everything else is a retryable unknown carrying the API's
  /// error code for logs.
  static AuthException _mapDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AuthException(AuthErrorCode.network, error.message);
      case DioExceptionType.badCertificate:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return AuthException(AuthErrorCode.unknown, _apiMessage(error));
    }
  }

  static String? _apiMessage(DioException error) {
    final data = error.response?.data;
    final detail = data is Map ? data['error'] : null;
    if (detail is Map && detail['code'] is String) {
      return '${error.response?.statusCode} ${detail['code']}';
    }
    return error.message;
  }
}
