import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen.terms({super.key}) : _isTerms = true;
  const LegalScreen.privacy({super.key}) : _isTerms = false;

  final bool _isTerms;

  // Theme follows the side that opened it: rose for nanny, purple for family.
  bool get _isNanny => Get.find<AuthController>().currentUser.value?.isNanny == true;
  Color get _accent => _isNanny ? KafiColors.roseD : KafiColors.pur;
  Color get _titleColor => _isNanny ? KafiColors.roseD : const Color(0xFF5A2090);
  List<Color> get _heroColors => _isNanny
      ? const [Color(0xFFFFE0EC), Color(0xFFFFF4EE)]
      : const [Color(0xFFEEE0FF), Color(0xFFF0D8FF)];

  @override
  Widget build(BuildContext context) {
    final title = _isTerms ? AppStrings.legalTermsTitle.tr : AppStrings.legalPrivacyTitle.tr;
    final points = _isTerms ? _termsPoints : _privacyPoints;
    return Scaffold(
      backgroundColor: KafiColors.bgLight,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _hero(title),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(AppStrings.legalLastUpdated.tr,
                      style: KafiTheme.nunito(10, color: KafiColors.ts)),
                  const SizedBox(height: 12),
                  ...List.generate(points.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: _accent,
                            child: Text('${i + 1}',
                                style: KafiTheme.nunito(10, color: Colors.white, w: FontWeight.w900)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(points[i],
                                style: KafiTheme.nunito(12, color: KafiColors.td).copyWith(height: 1.45)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _heroColors,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: AppNavigation.back,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_back, color: _accent, size: 20),
            ),
          ),
          Expanded(
            child: Text(title, style: KafiTheme.pacifico(17, color: _titleColor)),
          ),
        ],
      ),
    );
  }

  static const List<String> _termsPoints = [
    'Kafi is a marketplace only — we do not employ, sponsor, or act as a recruitment agency.',
    'You must be 18+ and provide accurate information. You must comply with UAE laws.',
    'Profile accuracy and document verification are your responsibility.',
    'Communication may be monitored for safety. We never ask for your OTP.',
    'Subscription fees are billed in AED. 5% VAT applies.',
    'We are not liable for the relationship between family and nanny.',
    'We may terminate accounts that breach these terms.',
    'These terms are governed by UAE law.',
  ];

  static const List<String> _privacyPoints = [
    'Data collected: personal info, documents, profile media, technical telemetry.',
    'We use your data to match nannies with families and to improve safety.',
    'You consent to data processing when you create an account.',
    'Phone numbers: nanny numbers are visible to subscribed families; family numbers stay private.',
    'We share limited data with payment, SMS, and storage providers only.',
    'Your data is encrypted in transit and at rest.',
    'You can request export or deletion at any time from Settings.',
    'You must be 18+ to use Kafi.',
  ];
}
