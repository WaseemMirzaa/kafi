import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/nanny_profile_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

class NannyPendingScreen extends StatefulWidget {
  const NannyPendingScreen({super.key});

  @override
  State<NannyPendingScreen> createState() => _NannyPendingScreenState();
}

class _NannyPendingScreenState extends State<NannyPendingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NannyProfileController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5EEFF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _pendingHero(),
              _docStatusList(ctrl),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                child: GestureDetector(
                  onTap: () => Get.toNamed(Routes.nannyDocs),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: KafiColors.roseP,
                      border: Border.all(
                          color: KafiColors.roseL, width: 2, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      '+ Upload Emirates ID · or tap "Not applicable (visit visa)"',
                      textAlign: TextAlign.center,
                      style: KafiTheme.fredoka(12, color: KafiColors.roseD, w: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pendingHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5EEFF), Color(0xFFFFE8F5)],
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFB5C8), Color(0xFFFF8FAB)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5C8A)
                        .withValues(alpha: 0.25 + _pulse.value * 0.15),
                    blurRadius: 10 + _pulse.value * 14,
                    spreadRadius: _pulse.value * 4,
                  ),
                ],
              ),
              child: const Icon(Icons.schedule, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(height: 11),
          Text(
            'Profile submitted! 🌸',
            style: KafiTheme.nunito(16, color: KafiColors.td, w: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            'Admin is reviewing your documents.\nThis usually takes 1–24 hours.',
            textAlign: TextAlign.center,
            style: KafiTheme.nunito(10.5, color: KafiColors.ts, w: FontWeight.w600)
                .copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x26FF8FAB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'While you wait:',
                  style: KafiTheme.nunito(10, color: KafiColors.roseD, w: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                _waitItem('✓ Your profile is saved and secure'),
                _waitItem("✓ We'll notify you when approved"),
                _waitItem('✓ You can edit your profile anytime'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _waitItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(text,
            style: KafiTheme.nunito(9.5, color: KafiColors.tm, w: FontWeight.w600)),
      );

  Widget _docStatusList(NannyProfileController ctrl) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFFD8E8), width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: KafiColors.roseP,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Text('📋 Document Status',
                style: KafiTheme.nunito(10, color: KafiColors.tm, w: FontWeight.w800)),
          ),
          Obx(() {
            final docMap = ctrl.documents;
            final items = [
              (DocumentType.passport, Icons.book_outlined, 'Passport Copy', KafiColors.grnL, KafiColors.grnD),
              (DocumentType.visa, Icons.credit_card_outlined, AppStrings.docVisa.tr, KafiColors.grnL, KafiColors.grnD),
              (DocumentType.emiratesId, Icons.badge_outlined, 'Emirates ID', KafiColors.ambL, const Color(0xFFA06010)),
              (DocumentType.trainingCert, Icons.videocam_outlined, 'Intro Video', KafiColors.purL, KafiColors.pur),
            ];
            return Column(
              children: items.asMap().entries.map((e) {
                final idx = e.key;
                final (type, icon, name, icBg, icColor) = e.value;
                final doc = docMap[type];
                final isLast = idx == items.length - 1;
                final (statusLabel, statusBg, statusFg) = _statusStyle(doc?.status);
                final subtitle = doc?.status == DocumentStatus.uploaded
                    ? 'Uploaded'
                    : doc?.status == DocumentStatus.reviewing
                        ? 'Under review'
                        : 'Not uploaded yet';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : const Border(
                            bottom: BorderSide(color: Color(0xFFFFF0F5), width: 1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: icBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 13, color: icColor),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: KafiTheme.nunito(10.5,
                                    color: KafiColors.td, w: FontWeight.w800)),
                            Text(subtitle,
                                style: KafiTheme.nunito(9, color: KafiColors.ts,
                                    w: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(statusLabel,
                            style:
                                KafiTheme.fredoka(9, color: statusFg, w: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  (String, Color, Color) _statusStyle(DocumentStatus? status) {
    return switch (status) {
      DocumentStatus.uploaded || DocumentStatus.reviewing =>
        ('Reviewing', KafiColors.grnL, KafiColors.grnD),
      DocumentStatus.approved => ('Approved ✓', KafiColors.grnL, KafiColors.grnD),
      DocumentStatus.rejected => ('Rejected', KafiColors.roseP, KafiColors.roseD),
      _ => ('Missing', KafiColors.ambL, const Color(0xFFA06010)),
    };
  }
}
