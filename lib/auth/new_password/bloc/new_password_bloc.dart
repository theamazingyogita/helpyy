import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_exception.dart';
import '../../data/auth_repository.dart';
import '../../form_status.dart';
import '../../validation.dart';

part 'new_password_event.dart';
part 'new_password_state.dart';

/// Picks a new password after a reset link. Saving signs the user in, which
/// reaches the app through AuthRepository changes.
class NewPasswordBloc extends Bloc<NewPasswordEvent, NewPasswordState> {
  NewPasswordBloc(this._repository) : super(const NewPasswordState()) {
    on<NewPasswordSubmitted>(_onSubmitted);
    on<NewPasswordCancelled>((_, _) => _repository.logOut());
  }

  final AuthRepository _repository;

  Future<void> _onSubmitted(
    NewPasswordSubmitted event,
    Emitter<NewPasswordState> emit,
  ) async {
    final passwordError = validateNewPassword(event.password);
    if (passwordError != null) {
      emit(NewPasswordState(passwordError: passwordError));
      return;
    }
    emit(const NewPasswordState(status: FormStatus.submitting));
    try {
      await _repository.setNewPassword(event.password);
    } on AuthException catch (error) {
      emit(NewPasswordState(status: FormStatus.failed, failure: error.failure));
    }
  }
}
