import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_exception.dart';
import '../../data/auth_repository.dart';
import '../../form_status.dart';
import '../../validation.dart';

part 'sign_up_event.dart';
part 'sign_up_state.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  SignUpBloc(this._repository) : super(const SignUpState()) {
    on<SignUpSubmitted>(_onSubmitted);
    on<SignUpFieldsEdited>((_, emit) {
      if (state.failure != null) emit(const SignUpState());
    });
  }

  final AuthRepository _repository;

  /// On success the repository announces the new user and the app moves on.
  Future<void> _onSubmitted(
    SignUpSubmitted event,
    Emitter<SignUpState> emit,
  ) async {
    final errors = SignUpState(
      nameError: validateName(event.name),
      emailError: validateEmail(event.email),
      passwordError: validateNewPassword(event.password),
    );
    if (errors.hasFieldErrors) {
      emit(errors);
      return;
    }
    emit(const SignUpState(status: FormStatus.submitting));
    try {
      await _repository.signUp(
        name: event.name,
        email: event.email,
        password: event.password,
      );
    } on AuthException catch (error) {
      emit(SignUpState(status: FormStatus.failed, failure: error.failure));
    }
  }
}
