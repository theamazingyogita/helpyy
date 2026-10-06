import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpyy/auth/validation.dart';

String typed(List<TextInputFormatter> formatters, String text) {
  var value = TextEditingValue.empty;
  final next = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
  var result = next;
  for (final formatter in formatters) {
    result = formatter.formatEditUpdate(value, result);
  }
  value = result;
  return value.text;
}

void main() {
  group('names', () {
    test('accepts real names in any script', () {
      for (final name in [
        'Al',
        'Anne-Marie',
        "O'Neil",
        'O’Neil',
        'J. R. Smith',
        'José Álvarez',
        '李雷',
        'Zoë ',
      ]) {
        expect(validateName(name), isNull, reason: name);
      }
    });

    test('rejects what is not a name', () {
      expect(validateName('   '), FieldError.required);
      expect(validateName('A'), FieldError.nameTooShort);
      expect(validateName('A.'), FieldError.nameTooShort);
      expect(validateName('Alex2'), FieldError.invalidName);
      expect(validateName('-Alex'), FieldError.invalidName);
      expect(validateName('Alex 😀'), FieldError.invalidName);
      expect(validateName('A' * 41), FieldError.tooLong);
    });

    test('the field drops digits, emoji, leading and doubled spaces', () {
      expect(typed(nameInputFormatters, ' Alex2 😀'), 'Alex ');
      expect(typed(nameInputFormatters, 'Mary  Ann'), 'Mary Ann');
      expect(typed(nameInputFormatters, 'B' * 60).length, maxNameLength);
    });
  });

  group('emails', () {
    test('accepts ordinary addresses', () {
      for (final email in [
        'alex@example.com',
        'alex.smith+helpyy@mail.example.co.uk',
        ' alex@example.io ',
        "o'neil@example.org",
      ]) {
        expect(validateEmail(email), isNull, reason: email);
      }
    });

    test('rejects malformed addresses', () {
      expect(validateEmail(''), FieldError.required);
      for (final email in [
        'alex',
        'alex@',
        '@example.com',
        'alex@example',
        'alex@example.c',
        'alex@@example.com',
        '.alex@example.com',
        'alex.@example.com',
        'al..ex@example.com',
        'alex@-example.com',
        'alex@example-.com',
        'alex@exa_mple.com',
        'alex@example.123',
        '${'a' * 65}@example.com',
      ]) {
        expect(validateEmail(email), FieldError.invalidEmail, reason: email);
      }
      expect(
        validateEmail('${'a' * 60}@${'b' * 60}.${'c' * 60}.${'d' * 80}.com'),
        FieldError.tooLong,
      );
    });

    test('the field drops spaces', () {
      expect(
        typed(emailInputFormatters, ' alex @example.com\t'),
        'alex@example.com',
      );
    });
  });

  group('new passwords', () {
    test('need 8 to 72 characters with a letter and a number', () {
      expect(validateNewPassword(''), FieldError.required);
      expect(validateNewPassword('abc1'), FieldError.tooShort);
      expect(validateNewPassword('abcdefgh'), FieldError.weakPassword);
      expect(validateNewPassword('12345678'), FieldError.weakPassword);
      expect(validateNewPassword('a1${'x' * 71}'), FieldError.tooLong);
      expect(validateNewPassword('password1'), isNull);
      expect(validateNewPassword('пароль123'), isNull);
    });

    test('the field stops at 72 characters', () {
      expect(
        typed(passwordInputFormatters, 'x' * 100).length,
        maxPasswordLength,
      );
    });
  });
}
