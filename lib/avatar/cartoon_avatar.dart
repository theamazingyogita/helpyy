import 'package:dicebear_core/dicebear_core.dart';
import 'package:dicebear_styles/adventurer.dart';

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

  static String? seedOf(String? url) {
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || uri.scheme != _scheme) return null;
    return Uri.decodeComponent(uri.path);
  }

  static String svgFor(String seed) =>
      _svgs[seed] ??= Avatar(_style, {'seed': seed}).svg;
}
