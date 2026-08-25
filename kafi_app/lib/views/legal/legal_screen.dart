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

  static List<String> get _termsPoints => [
        AppStrings.legalTerms1.tr,
        AppStrings.legalTerms2.tr,
        AppStrings.legalTerms3.tr,
        AppStrings.legalTerms4.tr,
        AppStrings.legalTerms5.tr,
        AppStrings.legalTerms6.tr,
        AppStrings.legalTerms7.tr,
        AppStrings.legalTerms8.tr,
      ];

  static List<String> get _privacyPoints => [
        AppStrings.legalPrivacy1.tr,
        AppStrings.legalPrivacy2.tr,
        AppStrings.legalPrivacy3.tr,
        AppStrings.legalPrivacy4.tr,
        AppStrings.legalPrivacy5.tr,
        AppStrings.legalPrivacy6.tr,
        AppStrings.legalPrivacy7.tr,
        AppStrings.legalPrivacy8.tr,
      ];
}
