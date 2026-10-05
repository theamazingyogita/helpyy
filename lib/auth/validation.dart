import 'package:flutter/services.dart';

enum FieldError {
  required('Required'),
  nameTooShort('At least 2 letters'),
  invalidName('Use letters, spaces, hyphens or apostrophes'),
  invalidEmail('Enter a valid email'),
  tooShort('At least 8 characters'),
  tooLong('Too long'),
  weakPassword('Use at least one letter and one number');

  const FieldError(this.message);

  final String message;
}

const minNameLength = 2;
const maxNameLength = 40;
const maxEmailLength = 254;
const minPasswordLength = 8;

/// Supabase Auth hashes passwords with bcrypt, which ignores anything past
/// 72 bytes.
const maxPasswordLength = 72;

// Letters in any script, joined by single runs of spaces, apostrophes,
// hyphens or dots: "Anne-Marie", "O'Neil", "J. R. Smith", "José", "李雷".
final _name = RegExp(
  r"^[\p{L}\p{M}]+(?:[ '’.-]+[\p{L}\p{M}]+)*\.?$",
  unicode: true,
);

// A practical address check, not the whole RFC: no dots at either end of
// the local part or doubled, domain labels of up to 63 letters, digits or
// inner hyphens, and a top level domain of letters.
final _email = RegExp(
  r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*"
  r'@(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,63}$',
);

final _letter = RegExp(r'\p{L}', unicode: true);
final _digit = RegExp(r'\d');

FieldError? validateName(String value) {
  final name = value.trim();
  if (name.isEmpty) return FieldError.required;
  if (name.length > maxNameLength) return FieldError.tooLong;
  if (!_name.hasMatch(name)) return FieldError.invalidName;
  if (name.replaceAll(RegExp(r"[ '’.-]"), '').length < minNameLength) {
    return FieldError.nameTooShort;
  }
  return null;
}

FieldError? validateEmail(String value) {
  final email = value.trim();
  if (email.isEmpty) return FieldError.required;
  if (email.length > maxEmailLength) return FieldError.tooLong;
  final at = email.lastIndexOf('@');
  // The part before the @ is limited to 64 characters.
  if (at > 64 || !_email.hasMatch(email)) return FieldError.invalidEmail;
  return null;
}

/// For a new password. Log in only checks that one was typed, so accounts
/// made under older rules can still get in.
FieldError? validateNewPassword(String value) {
  if (value.isEmpty) return FieldError.required;
  if (value.length < minPasswordLength) return FieldError.tooShort;
  if (value.length > maxPasswordLength) return FieldError.tooLong;
  if (!_letter.hasMatch(value) || !_digit.hasMatch(value)) {
    return FieldError.weakPassword;
  }
  return null;
}

/// Keeps a name field to characters [validateName] accepts, without leading
/// or doubled spaces.
final nameInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(
    RegExp(r"[\p{L}\p{M} '’.-]", unicode: true),
  ),
  FilteringTextInputFormatter.deny(RegExp(r'^ +')),
  FilteringTextInputFormatter.deny(RegExp(r'(?<= ) ')),
  LengthLimitingTextInputFormatter(maxNameLength),
];

/// Email addresses never contain spaces.
final emailInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.deny(RegExp(r'\s')),
  LengthLimitingTextInputFormatter(maxEmailLength),
];

final passwordInputFormatters = <TextInputFormatter>[
  LengthLimitingTextInputFormatter(maxPasswordLength),
];
