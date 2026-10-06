part of 'new_password_bloc.dart';

sealed class NewPasswordEvent {
  const NewPasswordEvent();
}

final class NewPasswordSubmitted extends NewPasswordEvent {
  const NewPasswordSubmitted(this.password);

  final String password;
}

/// Ends the reset without a new password, back to log in.
final class NewPasswordCancelled extends NewPasswordEvent {
  const NewPasswordCancelled();
}
