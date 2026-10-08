import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class ClubColors {
  static const paper = Color(0xFFFFFEFD);
  static const ink = Color(0xFF1A1A1A);
  static const muted = Color(0xFF484848);
  static const disabled = Color(0xFFA3A3A3);
  static const brand = Color(0xFF994EA8);
  static const soft = Color(0xFFEAD4F0);
  static const plum = Color(0xFF64316E);
  static const error = Color(0xFF9E3328);
  static const border = Color(0x261A1A1A);
  static const track = Color(0xFFEEE9E6);
  static const field = Color(0xFFFFFFFF);
  static const disabledFill = Color(0xFFE9E6E3);
  static const disabledLine = Color(0xFFDEDAD7);
  static const disabledText = Color(0xFF888888);
  static const pressed = Color(0xFFF4F1EF);
}

abstract final class ClubType {
  static TextStyle lora(
    double size, {
    Color color = ClubColors.ink,
    double height = 1.16,
  }) {
    return GoogleFonts.lora(
      fontSize: size,
      fontWeight: FontWeight.w500,
      height: height,
      letterSpacing: size * -0.025,
      color: color,
    );
  }

  static TextStyle inter(
    double size, {
    Color color = ClubColors.ink,
    FontWeight weight = FontWeight.w400,
    double height = 1.5,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle get eyebrow => inter(
    11,
    color: ClubColors.muted,
    weight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 1.32,
  );
}

ThemeData clubTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: ClubColors.paper,
    colorScheme: const ColorScheme.light(
      surface: ClubColors.paper,
      primary: ClubColors.ink,
      onPrimary: ClubColors.paper,
      error: ClubColors.error,
    ),
    splashColor: ClubColors.pressed,
    highlightColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: ClubColors.ink, displayColor: ClubColors.ink),
  );
}
