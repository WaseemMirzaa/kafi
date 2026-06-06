import 'package:flutter/material.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:kafi_app/views/widgets/kafi_form_header.dart';

class KafiStepScaffold extends StatelessWidget {
  const KafiStepScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.children,
    this.onBack,
  });

  final int step;
  final String title;
  final String subtitle;
  final Widget footer;
  final List<Widget> children;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KafiColors.nannyBg,
      body: SafeArea(
        child: Column(
          children: [
            KafiFormHeader(title: title, subtitle: subtitle, step: step, onBack: onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: footer,
            ),
          ],
        ),
      ),
    );
  }
}
