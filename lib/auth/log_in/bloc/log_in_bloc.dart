import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_exception.dart';
import '../../data/auth_repository.dart';
import '../../form_status.dart';
import '../../validation.dart';

part 'log_in_event.dart';
part 'log_in_state.dart';

class LogInBloc extends Bloc<LogInEvent, LogInState> {
  LogInBloc(this._repository) : super(const LogInState()) {
    on<LogInSubmitted>(_onSubmitted);
    on<LogInFieldsEdited>((_, emit) {
      if (state.failure != null) emit(const LogInState());
    });
  }

  final AuthRepository _repository;

  Future<void> _onSubmitted(
    LogInSubmitted event,
    Emitter<LogInState> emit,
  ) async {
    final emailError = validateEmail(event.email);
    final passwordError = event.password.isEmpty ? FieldError.required : null;
    if (emailError != null || passwordError != null) {
      emit(LogInState(emailError: emailError, passwordError: passwordError));
      return;
    }
    emit(const LogInState(status: FormStatus.submitting));
    try {
      await _repository.logIn(email: event.email, password: event.password);
    } on AuthException catch (error) {
      emit(LogInState(status: FormStatus.failed, failure: error.failure));
    }
  }
}
