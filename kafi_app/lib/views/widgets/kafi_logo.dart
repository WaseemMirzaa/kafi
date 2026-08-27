import 'package:flutter/material.dart';
import 'package:kafi_app/utils/constants/brand_constants.dart';

/// Full Kafi logo lockup from [BrandConstants.kafiLogoAsset].
class KafiLogo extends StatelessWidget {
  const KafiLogo({super.key, this.size = 32});

  /// Logo height; width scales from the asset aspect ratio.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      BrandConstants.kafiLogoAsset,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
