import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ════════════════════════════════════════════════════════════════════════════
//  AuraMonitor Pro — Cyberpunk Design System
// ════════════════════════════════════════════════════════════════════════════

class AuraTheme {
  AuraTheme._();

  // ── Palette ──────────────────────────────────────────────────────────────
  static const cyan      = Color(0xFF00F5FF);
  static const purple    = Color(0xFFBD00FF);
  static const orange    = Color(0xFFFF6B35);
  static const darkBg    = Color(0xFF050810);
  static const darkCard  = Color(0xFF0D1117);
  static const panelFill = Color(0x26FFFFFF);   // 15% white
  static const success   = Color(0xFF00FF88);
  static const danger    = Color(0xFFFF2D55);
  static const warn      = Color(0xFFFFD60A);
  static const textPrim  = Color(0xFFE8F4FD);
  static const textSec   = Color(0xFF7E9CC0);

  // ── Gradient — "Color Noise" cyberpunk mesh ───────────────────────────────
  static const bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [
      Color(0xFF060A1A),
      Color(0xFF0D0520),
      Color(0xFF1A0A0A),
      Color(0xFF070D1A),
    ],
    stops: [0.0, 0.35, 0.70, 1.0],
  );

  static const accentGradient = LinearGradient(
    colors: [cyan, purple, orange],
  );

  // ── Glow helper ───────────────────────────────────────────────────────────
  static List<BoxShadow> neonGlow(Color color, {double spread = 4}) => [
    BoxShadow(color: color.withAlpha(100), blurRadius: 12, spreadRadius: spread),
    BoxShadow(color: color.withAlpha(50),  blurRadius: 24, spreadRadius: spread * 2),
  ];

  static BoxDecoration glowBorder(Color color) => BoxDecoration(
    color:        panelFill,
    borderRadius: BorderRadius.circular(16),
    border:       Border.all(color: color.withAlpha(153), width: 1.5),
    boxShadow:    neonGlow(color, spread: 2),
  );

  // ── Gauge colour by load ──────────────────────────────────────────────────
  static Color gaugeColor(double normalized) {
    if (normalized < 0.5)       return Color.lerp(success, cyan, normalized * 2)!;
    if (normalized < 0.75)      return Color.lerp(cyan, warn, (normalized - 0.5) * 4)!;
    return Color.lerp(warn, danger, (normalized - 0.75) * 4)!;
  }

  // ── Typography ─────────────────────────────────────────────────────────────
  static TextStyle orbitron(double size, {FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.orbitron(fontSize: size, fontWeight: weight, color: color ?? textPrim,
          letterSpacing: 1.2);

  static TextStyle inter(double size, {FontWeight weight = FontWeight.w400, Color? color}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color ?? textPrim);

  // ── Material ThemeData ────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    brightness:      Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    colorScheme:     const ColorScheme.dark(
      primary:   cyan,
      secondary: purple,
      error:     danger,
      surface:   darkCard,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    useMaterial3: true,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
