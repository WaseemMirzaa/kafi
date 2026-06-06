import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';

export 'kafi_colors.dart';

abstract class KafiTheme {
  /// Status bar is always dark (dark icons on the app's light backgrounds).
  static const SystemUiOverlayStyle darkStatusBar = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  static ThemeData get light {
    final nunito = GoogleFonts.nunitoTextTheme();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: KafiColors.roseP,
      colorScheme: ColorScheme.fromSeed(
        seedColor: KafiColors.rose,
        primary: KafiColors.roseD,
        secondary: KafiColors.pur,
      ),
      appBarTheme: const AppBarTheme(systemOverlayStyle: darkStatusBar),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: KafiColors.roseD.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 4,
          shadowColor: KafiColors.roseD.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textTheme: nunito.apply(
        bodyColor: KafiColors.td,
        displayColor: KafiColors.td,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KafiColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KafiColors.cardBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KafiColors.cardBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KafiColors.roseD, width: 1.5),
        ),
        hintStyle: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: KafiColors.ts,
        ),
      ),
    );
  }

  static TextStyle pacifico(double size, {Color? color}) =>
      GoogleFonts.pacifico(fontSize: size, color: color ?? KafiColors.roseD);

  static TextStyle fredoka(double size,
          {Color? color, FontWeight w = FontWeight.w700}) =>
      GoogleFonts.fredoka(fontSize: size, fontWeight: w, color: color);

  static TextStyle nunito(double size,
          {Color? color, FontWeight w = FontWeight.w600}) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: w, color: color);
}
