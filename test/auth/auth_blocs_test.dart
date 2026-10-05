import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/auth/bloc/auth_bloc.dart';
import 'package:helpyy/auth/data/app_user.dart';
import 'package:helpyy/auth/data/auth_exception.dart';
import 'package:helpyy/auth/form_status.dart';
import 'package:helpyy/auth/log_in/bloc/log_in_bloc.dart';
import 'package:helpyy/auth/sign_up/bloc/sign_up_bloc.dart';
import 'package:helpyy/auth/validation.dart';
import 'package:helpyy/profile/bloc/profile_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';
import '../helpers/settle.dart';

void main() {
  const alex = AppUser(id: '1', name: 'Alex', email: 'alex@example.com');

  late MockAuthRepository auth;
  late StreamController<AppUser?> changes;

  setUp(() {
    auth = MockAuthRepository();
    changes = StreamController<AppUser?>.broadcast();
    when(() => auth.changes).thenAnswer((_) => changes.stream);
    when(() => auth.logOut()).thenAnswer((_) async {});
  });

  tearDown(() => changes.close());

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'restores a saved session',
      setUp: () => when(() => auth.currentUser()).thenAnswer((_) async => alex),
      build: () => AuthBloc(auth),
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [const AuthState.signedIn(alex)],
    );

    blocTest<AuthBloc, AuthState>(
      'follows sign in and sign out',
      setUp: () => when(() => auth.currentUser()).thenAnswer((_) async => null),
      build: () => AuthBloc(auth),
      act: (bloc) async {
        bloc.add(const AuthStarted());
        await settle();
        changes
          ..add(alex)
          ..add(null);
      },
      expect: () => [
        const AuthState.signedOut(),
        const AuthState.signedIn(alex),
        const AuthState.signedOut(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'treats unreadable storage as signed out',
      setUp: () => when(
        () => auth.currentUser(),
      ).thenThrow(const AuthException(AuthFailure.unavailable)),
      build: () => AuthBloc(auth),
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [const AuthState.signedOut()],
    );

    blocTest<AuthBloc, AuthState>(
      'log out goes through the repository',
      build: () => AuthBloc(auth),
      act: (bloc) => bloc.add(const AuthLogOutRequested()),
      verify: (_) => verify(() => auth.logOut()).called(1),
    );
  });

  group('SignUpBloc', () {
    blocTest<SignUpBloc, SignUpState>(
      'shows field errors without calling the repository',
      build: () => SignUpBloc(auth),
      act: (bloc) => bloc.add(
        const SignUpSubmitted(name: ' ', email: 'nope', password: 'short'),
      ),
      expect: () => [
        const SignUpState(
          nameError: FieldError.required,
          emailError: FieldError.invalidEmail,
          passwordError: FieldError.tooShort,
        ),
      ],
      verify: (_) => verifyNever(
        () => auth.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ),
    );

    blocTest<SignUpBloc, SignUpState>(
      'reports a taken email',
      setUp: () => when(
        () => auth.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException(AuthFailure.emailTaken)),
      build: () => SignUpBloc(auth),
      act: (bloc) => bloc.add(
        const SignUpSubmitted(
          name: 'Alex',
          email: 'alex@example.com',
          password: 'password1',
        ),
      ),
      expect: () => [
        const SignUpState(status: FormStatus.submitting),
        const SignUpState(
          status: FormStatus.failed,
          failure: AuthFailure.emailTaken,
        ),
      ],
    );
  });

  group('LogInBloc', () {
    blocTest<LogInBloc, LogInState>(
      'needs an email and a password',
      build: () => LogInBloc(auth),
      act: (bloc) => bloc.add(const LogInSubmitted(email: '', password: '')),
      expect: () => [
        const LogInState(
          emailError: FieldError.required,
          passwordError: FieldError.required,
        ),
      ],
    );

    blocTest<LogInBloc, LogInState>(
      'reports wrong credentials',
      setUp: () => when(
        () => auth.logIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException(AuthFailure.wrongPassword)),
      build: () => LogInBloc(auth),
      act: (bloc) => bloc.add(
        const LogInSubmitted(email: 'alex@example.com', password: 'nope'),
      ),
      expect: () => [
        const LogInState(status: FormStatus.submitting),
        const LogInState(
          status: FormStatus.failed,
          failure: AuthFailure.wrongPassword,
        ),
      ],
    );
  });

  blocTest<LogInBloc, LogInState>(
    'typing again clears the error',
    build: () => LogInBloc(auth),
    seed: () => const LogInState(
      status: FormStatus.failed,
      failure: AuthFailure.noAccount,
    ),
    act: (bloc) => bloc.add(const LogInFieldsEdited()),
    expect: () => [const LogInState()],
  );

  group('ProfileBloc', () {
    blocTest<ProfileBloc, ProfileState>(
      'saves a chosen photo',
      setUp: () =>
          when(() => auth.updatePhoto(any())).thenAnswer((_) async => alex),
      build: () => ProfileBloc(auth),
      act: (bloc) => bloc.add(const ProfilePhotoChosen('/tmp/me.jpg')),
      expect: () => [
        const ProfileState(status: FormStatus.submitting),
        const ProfileState(),
      ],
      verify: (_) => verify(() => auth.updatePhoto('/tmp/me.jpg')).called(1),
    );

    blocTest<ProfileBloc, ProfileState>(
      'removing the photo passes null',
      setUp: () =>
          when(() => auth.updatePhoto(any())).thenAnswer((_) async => alex),
      build: () => ProfileBloc(auth),
      act: (bloc) => bloc.add(const ProfilePhotoRemoved()),
      verify: (_) => verify(() => auth.updatePhoto(null)).called(1),
    );

    blocTest<ProfileBloc, ProfileState>(
      'saves a picked character as an avatar URL',
      setUp: () =>
          when(() => auth.useAvatar(any())).thenAnswer((_) async => alex),
      build: () => ProfileBloc(auth),
      act: (bloc) => bloc.add(const ProfileAvatarChosen('Luna')),
      expect: () => [
        const ProfileState(status: FormStatus.submitting),
        const ProfileState(),
      ],
      verify: (_) => verify(() => auth.useAvatar('avatar:Luna')).called(1),
    );

    blocTest<ProfileBloc, ProfileState>(
      'reports a character that could not be saved',
      setUp: () => when(
        () => auth.useAvatar(any()),
      ).thenThrow(const AuthException(AuthFailure.unavailable)),
      build: () => ProfileBloc(auth),
      act: (bloc) => bloc.add(const ProfileAvatarChosen('Luna')),
      expect: () => [
        const ProfileState(status: FormStatus.submitting),
        const ProfileState(status: FormStatus.failed),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'reports a failed photo save',
      setUp: () => when(
        () => auth.updatePhoto(any()),
      ).thenThrow(const AuthException(AuthFailure.unavailable)),
      build: () => ProfileBloc(auth),
      act: (bloc) => bloc.add(const ProfilePhotoRemoved()),
      expect: () => [
        const ProfileState(status: FormStatus.submitting),
        const ProfileState(status: FormStatus.failed),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'saves a new name',
      setUp: () => when(
        () => auth.updateName(any()),
      ).thenAnswer((_) async => alex.copyWith(name: 'Alexa')),
      build: () => ProfileBloc(auth),
      act: (bloc) => bloc.add(const ProfileNameSaved('Alexa')),
      expect: () => [
        const ProfileState(status: FormStatus.submitting),
        const ProfileState(isSaved: true),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'rejects an empty name',
      build: () => ProfileBloc(auth),
      act: (bloc) => bloc.add(const ProfileNameSaved('  ')),
      expect: () => [const ProfileState(nameError: FieldError.required)],
    );

    blocTest<ProfileBloc, ProfileState>(
      'reports a failed save',
      setUp: () => when(
        () => auth.updateName(any()),
      ).thenThrow(const AuthException(AuthFailure.unavailable)),
      build: () => ProfileBloc(auth),
      act: (bloc) => bloc.add(const ProfileNameSaved('Alexa')),
      expect: () => [
        const ProfileState(status: FormStatus.submitting),
        const ProfileState(status: FormStatus.failed),
      ],
    );
  });
}
