import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.ink,
    required this.muted,
    required this.callBackground,
    required this.onCall,
    required this.accept,
    required this.decline,
  });

  static const standard = AppColors(
    ink: Color(0xFF141414),
    muted: Color(0xFF5E5A53),
    callBackground: Color(0xFF1E2847),
    onCall: Color(0xFFFFFFFF),
    accept: Color(0xFF4C8B50),
    decline: Color(0xFFC4403F),
  );

  final Color ink;
  final Color muted;
  final Color callBackground;
  final Color onCall;
  final Color accept;
  final Color decline;

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? standard;

  @override
  AppColors copyWith({
    Color? ink,
    Color? muted,
    Color? callBackground,
    Color? onCall,
    Color? accept,
    Color? decline,
  }) {
    return AppColors(
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      callBackground: callBackground ?? this.callBackground,
      onCall: onCall ?? this.onCall,
      accept: accept ?? this.accept,
      decline: decline ?? this.decline,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
      callBackground:
          Color.lerp(callBackground, other.callBackground, t) ?? callBackground,
      onCall: Color.lerp(onCall, other.onCall, t) ?? onCall,
      accept: Color.lerp(accept, other.accept, t) ?? accept,
      decline: Color.lerp(decline, other.decline, t) ?? decline,
    );
  }
}
