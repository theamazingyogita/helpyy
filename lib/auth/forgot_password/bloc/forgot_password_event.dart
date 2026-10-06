part of 'forgot_password_bloc.dart';

sealed class ForgotPasswordEvent {
  const ForgotPasswordEvent();
}

final class ForgotPasswordSubmitted extends ForgotPasswordEvent {
  const ForgotPasswordSubmitted(this.email);

  final String email;
}
