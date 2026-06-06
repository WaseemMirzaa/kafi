import 'package:flutter/material.dart';

/// Design tokens from kafi-platform-v8-final HTML :root
abstract class KafiColors {
  static const rose = Color(0xFFFF8FAB);
  static const roseD = Color(0xFFFF5C8A);
  static const roseL = Color(0xFFFFB5C8);
  static const roseP = Color(0xFFFFF0F5);

  static const pur = Color(0xFF9B6EDB);
  static const purL = Color(0xFFF5EEFF);
  static const purB = Color(0xFFE0C8F0);

  static const grn = Color(0xFF6DBF8A);
  static const grnL = Color(0xFFE8F8EE);
  static const grnD = Color(0xFF2E9A58);

  static const amb = Color(0xFFFFB347);
  static const ambL = Color(0xFFFFF4E0);

  static const navy = Color(0xFF1E2A4A);
  static const navyS = Color(0xFFE8EBF5);

  static const teal = Color(0xFF0EA5A0);

  static const td = Color(0xFF3D1A26);
  static const tm = Color(0xFF7A3A50);
  static const ts = Color(0xFFC490A0);

  static const cardBorder = Color(0xFFFFD8E8);
  static const inputBg = Color(0xFFFFF7FA);
  static const inputBgP = Color(0xFFFAF5FF);

  /// Neutral off-white app background (family flow / global scaffold).
  static const bgLight = Color(0xFFF8F7FB);

  /// Page background for the nanny app flow — plain white (matches the HTML
  /// phone body; the pink comes from hero gradients and rose chips, not the bg).
  static const nannyBg = Color(0xFFFFFFFF);

  static const welcomeGradient = [
    Color(0xFFFFE4EF),
    Color(0xFFFFF4EE),
  ];
  static const familyGradient = [
    Color(0xFFEEE0FF),
    Color(0xFFF5F0FF),
  ];
  static const successGradient = [
    Color(0xFFE8F8EE),
    Color(0xFFF5FFF8),
  ];

  // Additional semantic colors
  static const bg = Color(0xFFFFF7FA);
  static const dark = Color(0xFF3D1A26);
  static const grey = Color(0xFFA8A8A8);
  static const ambD = Color(0xFFE68A00);
  static const purpL = Color(0xFFF5EEFF);
  static const purpD = Color(0xFF7B5BD5);
  static const redL = Color(0xFFFFE5E5);
  static const redD = Color(0xFFE53935);

  /// HTML / UI-kit aliases (same tokens as above).
  static const rosePale = roseP;
  static const roseDark = roseD;
  static const roseLight = roseL;
  static const purple = pur;
  static const purpleLight = purL;
  static const green = grn;
  static const greenDark = grnD;
  static const greenLight = grnL;
  static const textMid = tm;
  static const textDark = td;
  static const textSoft = ts;
}
