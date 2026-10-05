import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/avatar/cartoon_avatar.dart';
import 'package:helpyy/auth/data/auth_exception.dart';
import 'package:helpyy/auth/data/local_auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late LocalAuthRepository auth;

  late Directory photos;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    photos = await Directory.systemTemp.createTemp('helpyy_photos');
    auth = LocalAuthRepository(prefs, photoDirectory: () async => photos);
  });

  tearDown(() => photos.delete(recursive: true));

  Future<void> signUpAlex() => auth.signUp(
    name: ' Alex ',
    email: 'Alex@Example.com',
    password: 'password1',
  );

  test('sign up starts a session that survives a restart', () async {
    await signUpAlex();

    final restarted = LocalAuthRepository(prefs);
    final user = await restarted.currentUser();
    expect(user?.name, 'Alex');
    expect(user?.email, 'alex@example.com');
  });

  test('never stores the password itself', () async {
    await signUpAlex();

    final stored = prefs.getStringList('accounts')!.single;
    expect(stored, isNot(contains('password1')));
  });

  test('rejects a second account with the same email', () async {
    await signUpAlex();

    expect(
      () => auth.signUp(name: 'B', email: 'alex@example.com', password: 'x'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.failure,
          'failure',
          AuthFailure.emailTaken,
        ),
      ),
    );
  });

  Matcher failsWith(AuthFailure failure) => throwsA(
    isA<AuthException>().having((e) => e.failure, 'failure', failure),
  );

  test('tells a missing account apart from a wrong password', () async {
    await signUpAlex();
    await auth.logOut();

    await expectLater(
      auth.logIn(email: 'sam@example.com', password: 'password1'),
      failsWith(AuthFailure.noAccount),
    );
    await expectLater(
      auth.logIn(email: 'alex@example.com', password: 'wrong-pass'),
      failsWith(AuthFailure.wrongPassword),
    );
  });

  test('logs in with the right password', () async {
    await signUpAlex();
    await auth.logOut();
    expect(await auth.currentUser(), isNull);

    final user = await auth.logIn(
      email: ' ALEX@example.com',
      password: 'password1',
    );
    expect(user.name, 'Alex');
  });

  test('announces session changes', () async {
    final changes = <Object?>[];
    auth.changes.listen((user) => changes.add(user?.name));

    await signUpAlex();
    await auth.updateName('Alexa');
    await auth.logOut();
    await Future<void>.delayed(Duration.zero);

    expect(changes, ['Alex', 'Alexa', null]);
  });

  test('a name change is kept for the next log in', () async {
    await signUpAlex();
    await auth.updateName('Alexa');
    await auth.logOut();

    final user = await auth.logIn(
      email: 'alex@example.com',
      password: 'password1',
    );
    expect(user.name, 'Alexa');
  });

  test('keeps a copy of a new photo and removes the old one', () async {
    await signUpAlex();
    final picked = File('${photos.path}/picked.jpg')..writeAsBytesSync([1, 2]);

    final first = await auth.updatePhoto(picked.path);
    final firstFile = File.fromUri(Uri.parse(first.photoUrl!));
    expect(firstFile.existsSync(), isTrue);
    expect(firstFile.path, isNot(picked.path));

    final second = await auth.updatePhoto(picked.path);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(second.photoUrl, isNot(first.photoUrl));
    expect(firstFile.existsSync(), isFalse);

    final removed = await auth.updatePhoto(null);
    expect(removed.photoUrl, isNull);
    expect((await auth.currentUser())?.photoUrl, isNull);
  });

  test('a character replaces the photo and deletes its file', () async {
    await signUpAlex();
    final picked = File('${photos.path}/picked.jpg')..writeAsBytesSync([1, 2]);
    final withPhoto = await auth.updatePhoto(picked.path);
    final photoFile = File.fromUri(Uri.parse(withPhoto.photoUrl!));

    final user = await auth.useAvatar(CartoonAvatar.urlFor('Milo'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(CartoonAvatar.seedOf(user.photoUrl), 'Milo');
    expect((await auth.currentUser())?.photoUrl, user.photoUrl);
    expect(photoFile.existsSync(), isFalse);
  });

  test('a photo that cannot be read is reported', () async {
    await signUpAlex();

    await expectLater(
      auth.updatePhoto('${photos.path}/missing.jpg'),
      failsWith(AuthFailure.unavailable),
    );
  });
}
