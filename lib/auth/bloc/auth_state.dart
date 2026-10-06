part of 'auth_bloc.dart';

enum AuthStatus {
  checking,
  signedOut,
  signedIn,

  /// A password reset link was opened. Nothing else is shown until a new
  /// password is saved or the reset is cancelled.
  resettingPassword,
}

class AuthState extends Equatable {
  const AuthState._(this.status, this.user);

  const AuthState.checking() : this._(AuthStatus.checking, null);

  const AuthState.signedOut() : this._(AuthStatus.signedOut, null);

  const AuthState.signedIn(AppUser user) : this._(AuthStatus.signedIn, user);

  const AuthState.resettingPassword()
    : this._(AuthStatus.resettingPassword, null);

  final AuthStatus status;
  final AppUser? user;

  @override
  List<Object?> get props => [status, user];
}
