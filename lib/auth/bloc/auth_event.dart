part of 'auth_bloc.dart';

sealed class AuthEvent {
  const AuthEvent();
}

final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthLogOutRequested extends AuthEvent {
  const AuthLogOutRequested();
}
