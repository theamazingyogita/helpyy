import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/auth/data/app_user.dart';
import 'package:helpyy/auth/data/demo_account_auth_repository.dart';
import 'package:helpyy/auth/data/local_auth_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mocks.dart';

void main() {
  const supabaseUser = AppUser(
    id: 'remote',
    name: 'Alex',
    email: 'alex@example.com',
  );

  late MockAuthRepository backend;
  late StreamController<AppUser?> backendChanges;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    backend = MockAuthRepository();
    backendChanges = StreamController<AppUser?>.broadcast();
    when(() => backend.changes).thenAnswer((_) => backendChanges.stream);
    when(() => backend.currentUser()).thenAnswer((_) async => null);
    when(() => backend.logOut()).thenAnswer((_) async {});
    when(() => backend.isResettingPassword).thenReturn(false);
  });

  tearDown(() => backendChanges.close());

  DemoAccountAuthRepository build() => DemoAccountAuthRepository(
    backend: backend,
    demo: LocalAuthRepository(prefs),
  );

  test('the demo login signs in on the phone without the backend', () async {
    final auth = build();

    final user = await auth.logIn(
      email: ' Demo@Helpyy.app ',
      password: DemoAccountAuthRepository.password,
    );

    expect(user.email, DemoAccountAuthRepository.email);
    expect(DemoAccountAuthRepository.isDemo(user), isTrue);
    verifyNever(
      () => backend.logIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  test('logging in to the demo twice reuses the same account', () async {
    final first = await build().logIn(
      email: DemoAccountAuthRepository.email,
      password: DemoAccountAuthRepository.password,
    );
    final auth = build();
    await auth.logOut();
    final second = await auth.logIn(
      email: DemoAccountAuthRepository.email,
      password: DemoAccountAuthRepository.password,
    );

    expect(second.id, first.id);
  });

  test('any other login goes to the backend', () async {
    when(
      () => backend.logIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => supabaseUser);

    final user = await build().logIn(
      email: DemoAccountAuthRepository.email,
      password: 'wrong-password1',
    );

    expect(user, supabaseUser);
  });

  test('the demo session survives a restart', () async {
    await build().logIn(
      email: DemoAccountAuthRepository.email,
      password: DemoAccountAuthRepository.password,
    );

    final restored = await build().currentUser();

    expect(restored?.email, DemoAccountAuthRepository.email);
    verifyNever(() => backend.currentUser());
  });

  test('logging out of the demo leaves the backend alone', () async {
    final auth = build();
    await auth.logIn(
      email: DemoAccountAuthRepository.email,
      password: DemoAccountAuthRepository.password,
    );
    await Future<void>.delayed(Duration.zero);
    final signedOut = auth.changes.first;

    await auth.logOut();

    expect(await signedOut, isNull);
    verifyNever(() => backend.logOut());
    expect(await auth.currentUser(), isNull);
  });

  test('backend events are ignored while the demo is in use', () async {
    final auth = build();
    await auth.logIn(
      email: DemoAccountAuthRepository.email,
      password: DemoAccountAuthRepository.password,
    );
    await Future<void>.delayed(Duration.zero);
    final seen = <AppUser?>[];
    final subscription = auth.changes.listen(seen.add);

    backendChanges.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(seen, isEmpty);
    await subscription.cancel();
  });
}
