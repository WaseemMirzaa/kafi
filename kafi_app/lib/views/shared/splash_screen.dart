import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_logo.dart';

/// Startup gate. Decides where to send the user before any other screen shows:
/// no session → welcome; blocked → blocked screen; otherwise the correct
/// home / pending-approval / next-missing-onboarding-step (see
/// [AuthController.bootstrapStartup]). Shown as the initial route so routing is
/// driven "from splash" for every launch. If the bootstrap fails (offline /
/// timeout) it shows a retry instead of spinning forever.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController _auth = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _auth.bootstrapStartup());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4EF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE4EF), Color(0xFFFFF4EE)],
          ),
        ),
        child: Center(
          child: Obx(() {
            final failed = _auth.startupError.value != null;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const KafiLogo(size: 30),
                const SizedBox(height: 24),
                if (!failed)
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: KafiColors.roseD,
                    ),
                  )
                else
                  _offlineRetry(),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _offlineRetry() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(
            AppStrings.startupOfflineTitle.tr,
            textAlign: TextAlign.center,
            style: KafiTheme.nunito(15, color: KafiColors.td, w: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.startupOfflineSub.tr,
            textAlign: TextAlign.center,
            style: KafiTheme.nunito(11, color: KafiColors.ts, w: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _auth.bootstrapStartup,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
              decoration: BoxDecoration(
                color: KafiColors.roseD,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppStrings.retry.tr,
                style: KafiTheme.nunito(12.5, color: Colors.white, w: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
