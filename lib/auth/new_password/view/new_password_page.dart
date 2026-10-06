import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../widgets/ink_button.dart';
import '../../../widgets/screen_heading.dart';
import '../../../widgets/text_link.dart';
import '../../form_status.dart';
import '../../widgets/auth_error_banner.dart';
import '../../widgets/password_field.dart';
import '../bloc/new_password_bloc.dart';

class NewPasswordPage extends StatelessWidget {
  const NewPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NewPasswordBloc(context.read()),
      child: const _NewPasswordView(),
    );
  }
}

class _NewPasswordView extends StatefulWidget {
  const _NewPasswordView();

  @override
  State<_NewPasswordView> createState() => _NewPasswordViewState();
}

class _NewPasswordViewState extends State<_NewPasswordView> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<NewPasswordBloc>().add(NewPasswordSubmitted(_password.text));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<NewPasswordBloc>();
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<NewPasswordBloc, NewPasswordState>(
          builder: (context, state) => AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              children: [
                const ScreenHeading(
                  eyebrow: 'Almost there',
                  title: 'Choose a new password.',
                ),
                const SizedBox(height: 32),
                PasswordField(
                  controller: _password,
                  hint: 'At least 8, with a letter and a number',
                  error: state.passwordError,
                  isNewPassword: true,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                AuthErrorBanner(failure: state.failure),
                const SizedBox(height: 16),
                InkButton(
                  label: 'Save password',
                  onPressed: state.status == FormStatus.submitting
                      ? null
                      : _submit,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextLink(
                    label: 'Cancel',
                    onPressed: () => bloc.add(const NewPasswordCancelled()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
