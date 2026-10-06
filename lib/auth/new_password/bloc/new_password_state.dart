part of 'new_password_bloc.dart';

class NewPasswordState extends Equatable {
  const NewPasswordState({
    this.status = FormStatus.idle,
    this.passwordError,
    this.failure,
  });

  final FormStatus status;
  final FieldError? passwordError;
  final AuthFailure? failure;

  @override
  List<Object?> get props => [status, passwordError, failure];
}
