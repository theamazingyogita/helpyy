import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../widgets/ink_button.dart';
import '../../../widgets/text_link.dart';
import '../../../widgets/top_bar.dart';
import '../../form_status.dart';
import '../../forgot_password/view/forgot_password_page.dart';
import '../../sign_up/view/sign_up_page.dart';
import '../../data/auth_exception.dart';
import '../../widgets/auth_error_banner.dart';
import '../../../widgets/screen_heading.dart';
import '../../validation.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/password_field.dart';
import '../../widgets/switch_auth_link.dart';
import '../bloc/log_in_bloc.dart';

class LogInPage extends StatelessWidget {
  const LogInPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const LogInPage());

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LogInBloc(context.read()),
      child: const _LogInView(),
    );
  }
}

class _LogInView extends StatefulWidget {
  const _LogInView();

  @override
  State<_LogInView> createState() => _LogInViewState();
}

class _LogInViewState extends State<_LogInView> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<LogInBloc>().add(
      LogInSubmitted(email: _email.text, password: _password.text),
    );
  }

  void _edited() => context.read<LogInBloc>().add(const LogInFieldsEdited());

  void _goToSignUp() {
    final navigator = Navigator.of(context);
    navigator.canPop()
        ? navigator.pushReplacement(SignUpPage.route())
        : navigator.push(SignUpPage.route());
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<LogInBloc, LogInState>(
          builder: (context, state) => AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                TopBar(onBack: navigator.canPop() ? navigator.pop : null),
                const SizedBox(height: 16),
                const ScreenHeading(
                  eyebrow: 'Welcome back',
                  title: 'Good to see you again.',
                ),
                const SizedBox(height: 32),
                LabeledField(
                  label: 'Email address',
                  controller: _email,
                  hint: 'you@example.com',
                  error: state.emailError,
                  onChanged: (_) => _edited(),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  inputFormatters: emailInputFormatters,
                ),
                const SizedBox(height: 24),
                PasswordField(
                  controller: _password,
                  hint: 'Your secret phrase',
                  error: state.passwordError,
                  onChanged: (_) => _edited(),
                  onSubmitted: (_) => _submit(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextLink(
                    label: 'Forgot password?',
                    onPressed: () => navigator.push(
                      ForgotPasswordPage.route(email: _email.text),
                    ),
                  ),
                ),
                AuthErrorBanner(
                  failure: state.failure,
                  actionLabel: state.failure == AuthFailure.noAccount
                      ? 'Sign up'
                      : null,
                  onAction: _goToSignUp,
                ),
                const SizedBox(height: 16),
                InkButton(
                  label: 'Step inside',
                  onPressed: state.status == FormStatus.submitting
                      ? null
                      : _submit,
                ),
                const SizedBox(height: 32),
                SwitchAuthLink(
                  question: 'New around here?',
                  action: 'Sign up',
                  onPressed: _goToSignUp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
