import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../widgets/ink_button.dart';
import '../../../widgets/top_bar.dart';
import '../../form_status.dart';
import '../../log_in/view/log_in_page.dart';
import '../../data/auth_exception.dart';
import '../../widgets/auth_error_banner.dart';
import '../../widgets/auth_heading.dart';
import '../../validation.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/password_field.dart';
import '../../widgets/switch_auth_link.dart';
import '../bloc/sign_up_bloc.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const SignUpPage());

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignUpBloc(context.read()),
      child: const _SignUpView(),
    );
  }
}

class _SignUpView extends StatefulWidget {
  const _SignUpView();

  @override
  State<_SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<_SignUpView> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<SignUpBloc>().add(
      SignUpSubmitted(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      ),
    );
  }

  void _edited() => context.read<SignUpBloc>().add(const SignUpFieldsEdited());

  void _goToLogIn() {
    final navigator = Navigator.of(context);
    navigator.canPop()
        ? navigator.pushReplacement(LogInPage.route())
        : navigator.push(LogInPage.route());
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SignUpBloc, SignUpState>(
          builder: (context, state) => AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                TopBar(onBack: navigator.canPop() ? navigator.pop : null),
                const SizedBox(height: 16),
                const AuthHeading(
                  eyebrow: 'Make it yours',
                  title: "Let's get you started.",
                ),
                const SizedBox(height: 32),
                LabeledField(
                  label: 'Your name',
                  controller: _name,
                  hint: 'How should we call you?',
                  error: state.nameError,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  inputFormatters: nameInputFormatters,
                ),
                const SizedBox(height: 24),
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
                  hint: 'At least 8, with a letter and a number',
                  error: state.passwordError,
                  isNewPassword: true,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                AuthErrorBanner(
                  failure: state.failure,
                  actionLabel: state.failure == AuthFailure.emailTaken
                      ? 'Log in'
                      : null,
                  onAction: _goToLogIn,
                ),
                const SizedBox(height: 16),
                InkButton(
                  label: 'Join helpyy',
                  onPressed: state.status == FormStatus.submitting
                      ? null
                      : _submit,
                ),
                const SizedBox(height: 32),
                SwitchAuthLink(
                  question: 'Already on helpyy?',
                  action: 'Log in',
                  onPressed: _goToLogIn,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
