part of 'auth_bloc.dart';

enum AuthStatus { checking, signedOut, signedIn }

class AuthState extends Equatable {
  const AuthState._(this.status, this.user);

  const AuthState.checking() : this._(AuthStatus.checking, null);

  const AuthState.signedOut() : this._(AuthStatus.signedOut, null);

  const AuthState.signedIn(AppUser user) : this._(AuthStatus.signedIn, user);

  final AuthStatus status;
  final AppUser? user;

  @override
  List<Object?> get props => [status, user];
}
