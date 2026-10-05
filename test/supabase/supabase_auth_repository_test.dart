import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/auth/data/auth_exception.dart';
import 'package:helpyy/auth/data/supabase_auth_repository.dart';
import 'package:http/http.dart' as http;

import 'fake_supabase.dart';

void main() {
  const userId = '7d6e3a52-2f4b-4c39-9b3c-0a1d2e3f4a5b';
  final user = {
    'id': userId,
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'alex@example.com',
    'app_metadata': <String, Object>{},
    'user_metadata': {'name': 'Alex'},
    'created_at': '2026-10-06T08:00:00Z',
  };

  String jwt() {
    String part(Object json) =>
        base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
    final exp = DateTime.now().add(const Duration(hours: 1));
    return '${part({'alg': 'HS256'})}.'
        '${part({'sub': userId, 'exp': exp.millisecondsSinceEpoch ~/ 1000})}'
        '.sig';
  }

  Map<String, Object> session() => {
    'access_token': jwt(),
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'refresh',
    'user': user,
  };

  http.Response authError(String code, {int status = 400}) =>
      // Older servers name the field error_code, newer ones code.
      FakeSupabase.json({
        'code': code,
        'error_code': code,
        'msg': code,
      }, status: status);

  Matcher failsWith(AuthFailure failure) => throwsA(
    isA<AuthException>().having((e) => e.failure, 'failure', failure),
  );

  test('signing up with email confirmation on asks to check email', () {
    final server = FakeSupabase((_) => FakeSupabase.json(user));

    expect(
      SupabaseAuthRepository(
        server.client,
      ).signUp(name: 'Alex', email: 'Alex@Example.com ', password: 'password1'),
      failsWith(AuthFailure.confirmEmail),
    );
  });

  test('sign up sends the name, a tidied email and the app link', () async {
    final server = FakeSupabase((_) => FakeSupabase.json(user));
    final auth = SupabaseAuthRepository(server.client);

    await expectLater(
      auth.signUp(name: ' Alex ', email: 'Alex@Example.com ', password: 'pw'),
      throwsA(isA<AuthException>()),
    );

    final request = server.requests.single;
    expect(
      request.url.queryParameters['redirect_to'],
      SupabaseAuthRepository.emailRedirect,
    );
    final body = jsonDecode(request.body) as Map;
    expect(body['email'], 'alex@example.com');
    expect(body['data'], {'name': 'Alex'});
  });

  test('an email already in use is reported as taken', () {
    final server = FakeSupabase(
      (_) => authError('user_already_exists', status: 422),
    );

    expect(
      SupabaseAuthRepository(
        server.client,
      ).signUp(name: 'Alex', email: 'alex@example.com', password: 'password1'),
      failsWith(AuthFailure.emailTaken),
    );
  });

  test('wrong email or password is one failure', () {
    final server = FakeSupabase((_) => authError('invalid_credentials'));

    expect(
      SupabaseAuthRepository(
        server.client,
      ).logIn(email: 'alex@example.com', password: 'nope'),
      failsWith(AuthFailure.badCredentials),
    );
  });

  test('logging in loads the profile and announces the user', () async {
    final server = FakeSupabase(
      (request) => request.url.path.startsWith('/auth/')
          ? FakeSupabase.json(session())
          : FakeSupabase.json({'name': 'Alex', 'photo_url': 'avatar:Milo'}),
    );
    final auth = SupabaseAuthRepository(server.client);
    final announced = auth.changes.first;

    final signedIn = await auth.logIn(
      email: 'alex@example.com',
      password: 'password1',
    );

    expect(signedIn.id, userId);
    expect(signedIn.name, 'Alex');
    expect(signedIn.email, 'alex@example.com');
    expect(signedIn.photoUrl, 'avatar:Milo');
    expect(await announced, signedIn);
    final profile = server.requests.last.url;
    expect(profile.path, '/rest/v1/profiles');
    expect(profile.queryParameters['id'], 'eq.$userId');
  });

  test('being offline is reported, not thrown raw', () {
    final server = FakeSupabase((_) => throw http.ClientException('down'));

    expect(
      SupabaseAuthRepository(
        server.client,
      ).logIn(email: 'alex@example.com', password: 'password1'),
      failsWith(AuthFailure.unavailable),
    );
  });
}
