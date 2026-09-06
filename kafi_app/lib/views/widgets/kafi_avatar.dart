import 'package:flutter/material.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_media_image.dart';

/// Squircle avatar shared across nanny/family cards, messages, and profile
/// headers: shows [photoUrl] when present (network URL, `data:` URI, or local
/// file path — see [KafiMediaImage]) and falls back to a gradient rounded
/// square with [fallbackText] initials whenever no photo has been uploaded.
/// Rounded-square (not circular) to match the app's existing icon/avatar
/// language — see the reference mockups in the Kafi edits spec.
class KafiAvatar extends StatelessWidget {
  const KafiAvatar({
    super.key,
    required this.photoUrl,
    required this.fallbackText,
    this.size = 44,
    this.gradient = const [Color(0xFF9B6EDB), Color(0xFFC084FC)],
    this.fontSize,
    this.badge,
    this.radius,
  });

  /// URL/path of the uploaded photo, or null/empty when none was uploaded.
  final String? photoUrl;

  /// Initials (or a single fallback letter) shown when [photoUrl] is absent.
  final String fallbackText;
  final double size;
  final List<Color> gradient;
  final double? fontSize;

  /// Optional small overlay (e.g. a verified checkmark) anchored bottom-right.
  final Widget? badge;

  /// Corner radius; defaults to a proportion of [size] matching the app's
  /// existing rounded-square icons/cards.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (photoUrl ?? '').trim().isNotEmpty;
    final borderRadius = BorderRadius.circular(radius ?? size * 0.28);
    final fallback = _fallback();
    final avatar = ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: size,
        height: size,
        // Always paint initials under the photo so a slow/broken URL never
        // leaves a blank tile in lists (chat, jobs, browse).
        child: hasPhoto
            ? Stack(
                fit: StackFit.expand,
                children: [
                  fallback,
                  KafiMediaImage(
                    url: photoUrl!.trim(),
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ],
              )
            : fallback,
      ),
    );
    if (badge == null) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(right: -1, bottom: -1, child: badge!),
      ],
    );
  }

  Widget _fallback() {
    final initial = fallbackText.trim().isNotEmpty ? fallbackText.trim()[0].toUpperCase() : '?';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: KafiTheme.fredoka(fontSize ?? size * 0.4, color: Colors.white, w: FontWeight.w900),
      ),
    );
  }
}
