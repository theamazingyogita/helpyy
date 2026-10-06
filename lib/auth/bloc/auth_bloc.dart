import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/app_user.dart';
import '../data/auth_exception.dart';
import '../data/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Who is signed in. Sign up, log in and profile edits go through
/// [AuthRepository], and this bloc follows its changes.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthState.checking()) {
    on<AuthStarted>(_onStarted);
    on<AuthLogOutRequested>((_, _) => _repository.logOut());
  }

  final AuthRepository _repository;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    try {
      final user = await _repository.currentUser();
      emit(
        _repository.isResettingPassword
            ? const AuthState.resettingPassword()
            : _stateFor(user),
      );
    } on AuthException {
      emit(const AuthState.signedOut());
    }
    await Future.wait([
      emit.forEach(_repository.changes, onData: _stateFor),
      emit.forEach(
        _repository.passwordResets,
        onData: (_) => const AuthState.resettingPassword(),
      ),
    ]);
  }

  AuthState _stateFor(AppUser? user) =>
      user == null ? const AuthState.signedOut() : AuthState.signedIn(user);
}
