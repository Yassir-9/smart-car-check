import 'package:flutter/material.dart';

/// Design tokens of the approved visual direction (mixed: light screens, dark
/// car and diagnosis cards). Values only; no logic.
class Ui {
  Ui._();

  // Colors
  static const primary = Color(0xFF2563EB);
  static const primaryText = Color(0xFF1D4ED8); // secondary buttons and links
  static const darkCard = Color(0xFF0F1B33); // car card / diagnosis header
  static const darkTile = Color(0xFF16264A); // tiles inside the dark card
  static const screenBg = Color(0xFFF4F6FB);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const iconBg = Color(0xFFE8EFFD);

  // Status (text on background)
  static const okText = Color(0xFF166534);
  static const okBg = Color(0xFFDCFCE7);
  static const warnText = Color(0xFF92400E);
  static const warnBg = Color(0xFFFEF3C7);
  static const dangerText = Color(0xFF991B1B);
  static const dangerBg = Color(0xFFFEE2E2);

  // Text on the dark card
  static const onDark = Color(0xFFFFFFFF);
  static const onDarkMuted = Color(0xFFC7D2EA);

  // Radii
  static const double rSmall = 12;
  static const double rButton = 16;
  static const double rCard = 18;
  static const double rCarCard = 24;

  // Spacing (multiples of 8, plus 4 and 12 where needed)
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;

  // Type sizes
  static const double screenTitle = 22; // weight 700
  static const double sectionTitle = 16;
  static const double body = 14.5;
  static const double secondary = 12.5;

  // Minimum touch target
  static const double minTouch = 48;

  static const fontFamily = 'IBMPlexSansArabic';
}
