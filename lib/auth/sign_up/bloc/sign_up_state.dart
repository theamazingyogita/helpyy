part of 'sign_up_bloc.dart';

class SignUpState extends Equatable {
  const SignUpState({
    this.status = FormStatus.idle,
    this.nameError,
    this.emailError,
    this.passwordError,
    this.failure,
  });

  final FormStatus status;
  final FieldError? nameError;
  final FieldError? emailError;
  final FieldError? passwordError;
  final AuthFailure? failure;

  bool get hasFieldErrors =>
      nameError != null || emailError != null || passwordError != null;

  @override
  List<Object?> get props => [
    status,
    nameError,
    emailError,
    passwordError,
    failure,
  ];
}
