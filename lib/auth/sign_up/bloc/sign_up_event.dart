part of 'sign_up_bloc.dart';

sealed class SignUpEvent {
  const SignUpEvent();
}

/// The user typed again, so an old error no longer applies.
final class SignUpFieldsEdited extends SignUpEvent {
  const SignUpFieldsEdited();
}

final class SignUpSubmitted extends SignUpEvent {
  const SignUpSubmitted({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;
}
