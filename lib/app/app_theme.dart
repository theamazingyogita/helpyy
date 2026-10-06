import 'package:flutter/material.dart';

import 'app_colors.dart';

const handwritingFont = 'PatrickHand';

const _cream = Color(0xFFEEEAE3);
const _creamDeep = Color(0xFFE3DED4);
const _periwinkle = Color(0xFF5567A3);
const _mustard = Color(0xFFD4A23E);

ThemeData buildAppTheme() {
  const ink = AppColors.standard;
  final colorScheme = const ColorScheme.light(
    primary: _periwinkle,
    onPrimary: Colors.white,
    secondary: _mustard,
    onSecondary: Color(0xFF141414),
    surface: _cream,
    onSurface: Color(0xFF141414),
    surfaceContainerHighest: _creamDeep,
    onSurfaceVariant: Color(0xFF5E5A53),
    outline: Color(0xFF141414),
    outlineVariant: Color(0xFFCFC9BE),
    error: Color(0xFFC4403F),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: 'DMSans',
    scaffoldBackgroundColor: _cream,
  ).textTheme;

  final textTheme = base.copyWith(
    displaySmall: base.displaySmall?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -1.5,
      height: 1.02,
    ),
    headlineLarge: base.headlineLarge?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -1.4,
      height: 1.02,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.6,
    ),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    bodyMedium: base.bodyMedium?.copyWith(color: ink.muted, height: 1.45),
    labelSmall: base.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 1.8,
      fontSize: 11,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: 'DMSans',
    textTheme: textTheme,
    scaffoldBackgroundColor: _cream,
    extensions: const [AppColors.standard],
    dividerTheme: const DividerThemeData(
      color: Color(0xFFCFC9BE),
      space: 1,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? Colors.white
            : const Color(0xFFF5F2EC),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF141414)),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF141414)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: _periwinkle, width: 3),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? _mustard
            : const Color(0xFF8A93B8),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _cream,
      surfaceTintColor: Colors.transparent,
      indicatorColor: _periwinkle,
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? _periwinkle
              : const Color(0xFF5E5A53),
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFF5E5A53),
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color(0xFF141414),
      shape: RoundedRectangleBorder(),
    ),
  );
}
