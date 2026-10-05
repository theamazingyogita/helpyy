import 'package:flutter/material.dart';

import '../validation.dart';
import 'labeled_field.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.hint,
    this.error,
    this.isNewPassword = false,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final FieldError? error;
  final bool isNewPassword;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  var _isHidden = true;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: 'Password',
      controller: widget.controller,
      hint: widget.hint,
      error: widget.error,
      obscureText: _isHidden,
      textInputAction: TextInputAction.done,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      inputFormatters: passwordInputFormatters,
      autofillHints: [
        widget.isNewPassword
            ? AutofillHints.newPassword
            : AutofillHints.password,
      ],
      suffix: IconButton(
        tooltip: _isHidden ? 'Show password' : 'Hide password',
        icon: Icon(
          _isHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () => setState(() => _isHidden = !_isHidden),
      ),
    );
  }
}
