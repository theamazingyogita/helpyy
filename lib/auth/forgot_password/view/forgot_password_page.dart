import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../widgets/ink_button.dart';
import '../../../widgets/screen_heading.dart';
import '../../../widgets/top_bar.dart';
import '../../form_status.dart';
import '../../validation.dart';
import '../../widgets/auth_error_banner.dart';
import '../../widgets/labeled_field.dart';
import '../bloc/forgot_password_bloc.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key, this.email = ''});

  /// [email] fills the field with what was typed on log in.
  static Route<void> route({String email = ''}) =>
      MaterialPageRoute(builder: (_) => ForgotPasswordPage(email: email));

  final String email;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ForgotPasswordBloc(context.read()),
      child: _ForgotPasswordView(email: email),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView({required this.email});

  final String email;

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  late final _email = TextEditingController(text: widget.email.trim());

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<ForgotPasswordBloc>().add(
      ForgotPasswordSubmitted(_email.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
          builder: (context, state) => ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              TopBar(onBack: navigator.pop),
              const SizedBox(height: 16),
              if (state.sentTo case final sentTo?) ...[
                ScreenHeading(
                  eyebrow: 'Check your email',
                  title: 'Help is on the way.',
                  body:
                      'If there is a helpyy account for $sentTo, a link to '
                      'choose a new password is in its inbox. Open it on this '
                      'phone.',
                ),
                const SizedBox(height: 32),
                InkButton(label: 'Back to log in', onPressed: navigator.pop),
              ] else ...[
                const ScreenHeading(
                  eyebrow: 'Locked out?',
                  title: 'Reset your password.',
                  body: "Enter your email and we'll send you a link.",
                ),
                const SizedBox(height: 32),
                LabeledField(
                  label: 'Email address',
                  controller: _email,
                  hint: 'you@example.com',
                  error: state.emailError,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  inputFormatters: emailInputFormatters,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                AuthErrorBanner(failure: state.failure),
                const SizedBox(height: 16),
                InkButton(
                  label: 'Send reset link',
                  onPressed: state.status == FormStatus.submitting
                      ? null
                      : _submit,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
