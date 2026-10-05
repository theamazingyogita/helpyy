part of 'auth_bloc.dart';

sealed class AuthEvent {
  const AuthEvent();
}

/// Restore the saved session and follow sign in and sign out from then on.
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthLogOutRequested extends AuthEvent {
  const AuthLogOutRequested();
}
