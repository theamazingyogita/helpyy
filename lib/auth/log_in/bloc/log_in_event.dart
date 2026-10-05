part of 'log_in_bloc.dart';

sealed class LogInEvent {
  const LogInEvent();
}

/// The user typed again, so an old error no longer applies.
final class LogInFieldsEdited extends LogInEvent {
  const LogInFieldsEdited();
}

final class LogInSubmitted extends LogInEvent {
  const LogInSubmitted({required this.email, required this.password});

  final String email;
  final String password;
}
