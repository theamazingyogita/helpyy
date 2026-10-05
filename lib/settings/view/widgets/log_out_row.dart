import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../widgets/circle_icon.dart';

class LogOutRow extends StatelessWidget {
  const LogOutRow({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.read<AuthBloc>().add(const AuthLogOutRequested()),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          spacing: 14,
          children: [
            const CircleIcon(Icons.logout),
            Expanded(
              child: Text(
                'Log out',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }
}
