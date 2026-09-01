import 'package:flutter/material.dart';

// ─── Maroon/Gold/Ivory Palette (exact match to HTML CSS variables) ─────────────
class AppColors {
  static const maroon900 = Color(0xFF3C0B12);
  static const maroon800 = Color(0xFF570F19);
  static const maroon700 = Color(0xFF7A1620);
  static const maroon600 = Color(0xFF93202B);

  static const gold500 = Color(0xFFC89B3C);
  static const gold300 = Color(0xFFE8CE8C);
  static const gold100 = Color(0xFFF6EACB);

  static const ivory = Color(0xFFFBF6EC);
  static const paper = Color(0xFFFFFDF8);

  static const ink = Color(0xFF2A1810);
  static const inkSoft = Color(0xFF6B5A4F);
  static const line = Color(0xFFE4D8C3);

  static const income = Color(0xFF2F6B4F);
  static const incomeBg = Color(0xFFEAF3EE);
  static const expense = Color(0xFFA43B3B);
  static const expenseBg = Color(0xFFFBEAEA);
  static const bank = Color(0xFF2C5B8A);
  static const bankBg = Color(0xFFE3EBF4);

  // transfer tag
  static const transfer = Color(0xFF5B3FA0);
  static const transferBg = Color(0xFFEAE3F4);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.maroon700,
          onPrimary: Colors.white,
          secondary: AppColors.gold500,
          onSecondary: AppColors.maroon900,
          error: AppColors.expense,
          onError: Colors.white,
          surface: AppColors.paper,
          onSurface: AppColors.ink,
          outline: AppColors.line,
        ),
        scaffoldBackgroundColor: AppColors.ivory,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.maroon900,
          foregroundColor: AppColors.gold100,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: AppColors.paper,
          elevation: 2,
          shadowColor: AppColors.maroon900.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.line),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.maroon700,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.line),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.paper,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.gold500, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          labelStyle: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700, color: AppColors.ink),
          headlineLarge: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700, color: AppColors.ink),
          headlineMedium: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700, color: AppColors.ink),
          titleLarge: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
          titleMedium: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
          bodyMedium: TextStyle(color: AppColors.ink),
          bodySmall: TextStyle(color: AppColors.inkSoft),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.paper,
          indicatorColor: AppColors.maroon700.withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: AppColors.maroon700, fontWeight: FontWeight.w600, fontSize: 12);
            }
            return const TextStyle(color: AppColors.inkSoft, fontSize: 12);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.maroon700);
            }
            return const IconThemeData(color: AppColors.inkSoft);
          }),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: AppColors.paper,
          selectedIconTheme: IconThemeData(color: AppColors.maroon700),
          unselectedIconTheme: IconThemeData(color: AppColors.inkSoft),
          selectedLabelTextStyle: TextStyle(color: AppColors.maroon700, fontWeight: FontWeight.w600),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.gold100,
          labelStyle: const TextStyle(fontSize: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      );
}