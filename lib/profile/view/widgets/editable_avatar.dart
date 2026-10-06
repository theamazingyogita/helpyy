import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../widgets/initial_avatar.dart';

class EditableAvatar extends StatelessWidget {
  const EditableAvatar({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.isBusy,
    required this.onEdit,
  });

  final String name;
  final String? photoUrl;
  final bool isBusy;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ink = AppColors.of(context).ink;
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ink, width: 1.5),
            ),
            child: InitialAvatar(name: name, photoUrl: photoUrl, size: 108),
          ),
          if (isBusy)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: IconButton.filled(
              tooltip: 'Change photo',
              onPressed: isBusy ? null : onEdit,
              icon: const Icon(Icons.photo_camera_outlined, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                side: BorderSide(color: ink, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
