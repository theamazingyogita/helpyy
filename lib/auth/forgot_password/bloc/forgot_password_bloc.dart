import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_exception.dart';
import '../../data/auth_repository.dart';
import '../../form_status.dart';
import '../../validation.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc(this._repository) : super(const ForgotPasswordState()) {
    on<ForgotPasswordSubmitted>(_onSubmitted);
  }

  final AuthRepository _repository;

  Future<void> _onSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    final emailError = validateEmail(event.email);
    if (emailError != null) {
      emit(ForgotPasswordState(emailError: emailError));
      return;
    }
    emit(const ForgotPasswordState(status: FormStatus.submitting));
    try {
      await _repository.sendPasswordReset(event.email);
      emit(ForgotPasswordState(sentTo: event.email.trim().toLowerCase()));
    } on AuthException catch (error) {
      emit(
        ForgotPasswordState(status: FormStatus.failed, failure: error.failure),
      );
    }
  }
}
