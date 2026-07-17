import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

/// Renders a media URL that may be an HTTP(S) URL, a `data:` URI, or a local
/// file path (mock uploads write temp files for reliable iOS/Android preview).
class KafiMediaImage extends StatelessWidget {
  const KafiMediaImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final fallback = errorBuilder ??
        (_, __, ___) => SizedBox(width: width, height: height);

    if (url.startsWith('data:')) {
      try {
        final comma = url.indexOf(',');
        if (comma < 0) return fallback(context, Object(), null);
        final bytes = base64Decode(url.substring(comma + 1));
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: fallback,
        );
      } catch (_) {
        return fallback(context, Object(), null);
      }
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: fallback,
      );
    }

    final file = File(url);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: fallback,
      );
    }

    return fallback(context, Object(), null);
  }
}
