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

const maxPasswordLength = 72;

final _name = RegExp(
  r"^[\p{L}\p{M}]+(?:[ '’.-]+[\p{L}\p{M}]+)*\.?$",
  unicode: true,
);

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
  if (at > 64 || !_email.hasMatch(email)) return FieldError.invalidEmail;
  return null;
}

FieldError? validateNewPassword(String value) {
  if (value.isEmpty) return FieldError.required;
  if (value.length < minPasswordLength) return FieldError.tooShort;
  if (value.length > maxPasswordLength) return FieldError.tooLong;
  if (!_letter.hasMatch(value) || !_digit.hasMatch(value)) {
    return FieldError.weakPassword;
  }
  return null;
}

final nameInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(
    RegExp(r"[\p{L}\p{M} '’.-]", unicode: true),
  ),
  FilteringTextInputFormatter.deny(RegExp(r'^ +')),
  FilteringTextInputFormatter.deny(RegExp(r'(?<= ) ')),
  LengthLimitingTextInputFormatter(maxNameLength),
];

final emailInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.deny(RegExp(r'\s')),
  LengthLimitingTextInputFormatter(maxEmailLength),
];

final passwordInputFormatters = <TextInputFormatter>[
  LengthLimitingTextInputFormatter(maxPasswordLength),
];
