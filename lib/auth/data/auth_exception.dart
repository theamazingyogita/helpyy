enum AuthFailure {
  emailTaken('An account with this email already exists.'),
  noAccount('There is no account with this email.'),
  wrongPassword('That password is not right. Check it and try again.'),

  /// The backend does not say which of the two was wrong.
  badCredentials('That email and password do not match. Try again.'),
  confirmEmail('Check your email and tap the link to confirm, then log in.'),
  weakPassword('That password is too easy to guess. Pick another.'),
  samePassword('That is your current password. Pick a new one.'),
  tooManyEmails('Too many emails sent. Wait a minute and try again.'),
  unavailable('Something went wrong. Try again.');

  const AuthFailure(this.message);

  final String message;
}

class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;

  @override
  String toString() => 'AuthException: ${failure.name}';
}
