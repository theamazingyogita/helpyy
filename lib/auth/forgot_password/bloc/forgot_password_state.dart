part of 'forgot_password_bloc.dart';

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.status = FormStatus.idle,
    this.emailError,
    this.failure,
    this.sentTo,
  });

  final FormStatus status;
  final FieldError? emailError;
  final AuthFailure? failure;

  final String? sentTo;

  @override
  List<Object?> get props => [status, emailError, failure, sentTo];
}
