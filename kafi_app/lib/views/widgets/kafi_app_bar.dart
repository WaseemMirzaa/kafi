import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

const _kGradient = [Color(0xFFFF8FAB), Color(0xFFFF4D82)];

class KafiAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KafiAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 4,
      shadowColor: const Color(0x44FF4D82),
      systemOverlayStyle: KafiTheme.darkStatusBar,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading ??
          (automaticallyImplyLeading && Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: Get.back,
                )
              : null),
      title: Text(title, style: KafiTheme.fredoka(16, color: Colors.white)),
      titleTextStyle: KafiTheme.fredoka(16, color: Colors.white),
      centerTitle: centerTitle,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _kGradient,
          ),
        ),
      ),
    );
  }
}
