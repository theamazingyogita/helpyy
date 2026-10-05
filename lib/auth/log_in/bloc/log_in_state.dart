part of 'log_in_bloc.dart';

class LogInState extends Equatable {
  const LogInState({
    this.status = FormStatus.idle,
    this.emailError,
    this.passwordError,
    this.failure,
  });

  final FormStatus status;
  final FieldError? emailError;
  final FieldError? passwordError;
  final AuthFailure? failure;

  @override
  List<Object?> get props => [status, emailError, passwordError, failure];
}
