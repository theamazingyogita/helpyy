import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app/app_theme.dart';
import '../avatar/cartoon_avatar.dart';

/// Round avatar: the photo or picked character when there is one, otherwise
/// the first letter of the name on mustard.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 56,
  });

  final String name;
  final String? photoUrl;
  final double size;

  ImageProvider? get _photo {
    final url = photoUrl;
    if (url == null) return null;
    final uri = Uri.parse(url);
    return uri.scheme == 'file'
        ? FileImage(File.fromUri(uri))
        : NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.secondary,
        shape: BoxShape.circle,
      ),
      child: Text(
        name.characters.take(1).toString().toUpperCase(),
        style: TextStyle(
          fontFamily: handwritingFont,
          fontSize: size * 0.5,
          height: 1,
          color: colorScheme.onSecondary,
        ),
      ),
    );
    if (CartoonAvatar.seedOf(photoUrl) case final seed?) {
      return Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.secondary,
          shape: BoxShape.circle,
        ),
        child: SvgPicture.string(CartoonAvatar.svgFor(seed)),
      );
    }
    final photo = _photo;
    if (photo == null) return initial;
    return ClipOval(
      child: Image(
        image: photo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // A missing or broken file falls back to the initial.
        errorBuilder: (_, _, _) => initial,
      ),
    );
  }
}
