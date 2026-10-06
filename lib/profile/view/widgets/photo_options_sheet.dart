import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../avatar/cartoon_avatar.dart';
import '../../../widgets/initial_avatar.dart';

sealed class PhotoChoice {
  const PhotoChoice();
}

final class PickFrom extends PhotoChoice {
  const PickFrom(this.source);

  final ImageSource source;
}

final class PickAvatar extends PhotoChoice {
  const PickAvatar(this.seed);

  final String seed;
}

final class RemovePhoto extends PhotoChoice {
  const RemovePhoto();
}

Future<PhotoChoice?> showPhotoOptions(
  BuildContext context, {
  required bool hasPhoto,
  String? currentSeed,
}) {
  return showModalBottomSheet<PhotoChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final textTheme = Theme.of(context).textTheme;
      final error = Theme.of(context).colorScheme.error;
      return SingleChildScrollView(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Pick a character', style: textTheme.titleSmall),
              ),
              _AvatarGrid(currentSeed: currentSeed),
              const SizedBox(height: 8),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.of(
                  context,
                ).pop(const PickFrom(ImageSource.camera)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from library'),
                onTap: () => Navigator.of(
                  context,
                ).pop(const PickFrom(ImageSource.gallery)),
              ),
              if (hasPhoto)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: error),
                  title: Text('Remove picture', style: TextStyle(color: error)),
                  onTap: () => Navigator.of(context).pop(const RemovePhoto()),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _AvatarGrid extends StatelessWidget {
  const _AvatarGrid({required this.currentSeed});

  final String? currentSeed;

  @override
  Widget build(BuildContext context) {
    final selected = Theme.of(context).colorScheme.primary;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        for (final seed in CartoonAvatar.seeds)
          Semantics(
            label: 'Character $seed',
            selected: seed == currentSeed,
            button: true,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(PickAvatar(seed)),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: seed == currentSeed ? selected : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => InitialAvatar(
                    name: seed,
                    photoUrl: CartoonAvatar.urlFor(seed),
                    size: constraints.biggest.shortestSide,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
