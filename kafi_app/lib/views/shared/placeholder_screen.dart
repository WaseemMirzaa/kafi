import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_app_bar.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.titleKey});

  final String titleKey;

  @override
  Widget build(BuildContext context) {
    final title = titleKey.tr;
    return Scaffold(
      appBar: KafiAppBar(title: title),
      body: Center(
        child: Text(
          '$title — ${'coming_soon'.tr}',
          style: KafiTheme.nunito(14, color: KafiColors.tm),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
