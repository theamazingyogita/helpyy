part of 'new_password_bloc.dart';

sealed class NewPasswordEvent {
  const NewPasswordEvent();
}

final class NewPasswordSubmitted extends NewPasswordEvent {
  const NewPasswordSubmitted(this.password);

  final String password;
}

final class NewPasswordCancelled extends NewPasswordEvent {
  const NewPasswordCancelled();
}
