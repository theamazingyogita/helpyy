import 'package:dicebear_core/dicebear_core.dart';
import 'package:dicebear_styles/adventurer.dart';

/// Ready made characters the user can pick instead of a photo, drawn with
/// DiceBear's Adventurer style.
///
/// A picked character is kept as the user's photo URL, `avatar:<seed>`, so
/// it travels through the same storage as a real photo. The same seed always
/// draws the same character.
///
/// The art is by Lisa Wischofsky under CC BY 4.0. The credit it requires is
/// in the dicebear_styles licence, shown by Settings > Licenses.
abstract final class CartoonAvatar {
  static const seeds = [
    'Felix',
    'Aneka',
    'Milo',
    'Luna',
    'Oscar',
    'Zara',
    'Kai',
    'Nova',
    'Leo',
    'Ivy',
    'Remy',
    'Sage',
  ];

  static const _scheme = 'avatar';

  static final _style = Style.parse(adventurer);
  static final _svgs = <String, String>{};

  static String urlFor(String seed) =>
      Uri(scheme: _scheme, path: seed).toString();

  /// The seed when [url] is a character, null for photos.
  static String? seedOf(String? url) {
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || uri.scheme != _scheme) return null;
    return Uri.decodeComponent(uri.path);
  }

  /// Rendering parses a large style definition, so each SVG is made once.
  static String svgFor(String seed) =>
      _svgs[seed] ??= Avatar(_style, {'seed': seed}).svg;
}
