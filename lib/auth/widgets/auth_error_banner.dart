import 'package:flutter/material.dart';

import '../../widgets/text_link.dart';
import '../data/auth_exception.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({
    super.key,
    required this.failure,
    this.actionLabel,
    this.onAction,
  });

  final AuthFailure? failure;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final failure = this.failure;
    if (failure == null) return const SizedBox.shrink();
    final error = Theme.of(context).colorScheme.error;
    final actionLabel = this.actionLabel;
    final onAction = this.onAction;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: error.withValues(alpha: 0.08),
          border: Border.all(color: error, width: 1.5),
        ),
        child: Row(
          spacing: 10,
          children: [
            Icon(Icons.error_outline, color: error),
            Expanded(
              child: Text(
                failure.message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: error),
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextLink(label: actionLabel, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}
