import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Text styles extracted from Figma design
/// Node: 761:5183 - Text styles
class AppTextStyles {
  // Colors
  static const Color baseText = Color(0xFF000000);
  static const Color grey = Color(0xFFD9D9D9);

  // Text Styles - Using ADLaM Display from Google Fonts

  /// Big title: ADLaM Display 60px
  static TextStyle get bigTitle => GoogleFonts.getFont(
    'ADLaM Display',
    fontSize: 60,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
    color: baseText,
  );

  /// Title in element: ADLaM Display 36px
  static TextStyle get titleInElement => GoogleFonts.getFont(
    'ADLaM Display',
    fontSize: 36,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
    color: baseText,
  );

  /// Task deadline: ADLaM Display 29.26px
  static TextStyle get taskDeadline => GoogleFonts.getFont(
    'ADLaM Display',
    fontSize: 29.26,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
    color: baseText,
  );

  /// Components 4: ADLaM Display 25px
  static TextStyle get components4 => GoogleFonts.getFont(
    'ADLaM Display',
    fontSize: 25,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
    color: baseText,
  );

  /// Settings header: ADLaM Display 23px
  static TextStyle get settingsHeader => GoogleFonts.getFont(
    'ADLaM Display',
    fontSize: 23,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
    color: baseText,
  );

  /// Heading 2: ADLaM Display 20px
  static TextStyle get heading2 => GoogleFonts.getFont(
    'ADLaM Display',
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
    color: baseText,
  );

  /// Footer in element: ADLaM Display 16px
  static TextStyle get footerInElement => GoogleFonts.getFont(
    'ADLaM Display',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
    color: baseText,
  );

  /// Task hour: ADLaM Display 14px
  static TextStyle get taskHour => GoogleFonts.getFont(
    'ADLaM Display',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
    color: baseText,
  );

  /// Component 6: ADLaM Display 12.8px with line height 19.2
  static TextStyle get component6 => GoogleFonts.getFont(
    'ADLaM Display',
    fontSize: 12.8,
    fontWeight: FontWeight.w400,
    height: 1.5, // 19.2 / 12.8 = 1.5
    letterSpacing: 0,
    color: baseText,
  );

  /// Plant style: Inter Medium 17.28px
  static TextStyle get plantStyle => GoogleFonts.inter(
    fontSize: 17.28,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0,
    color: baseText,
  );

  /// Caption: Inter Regular 12px
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
    color: baseText,
  );

  /// Medium style: Arimo Regular 14px with line height 20
  static TextStyle get mediumStyle => GoogleFonts.arimo(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43, // 20 / 14 ≈ 1.43
    letterSpacing: 0,
    color: baseText,
  );

  /// Component 5: Arimo Bold 14px with underline
  static TextStyle get component5 => GoogleFonts.arimo(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.43, // 20 / 14 ≈ 1.43
    letterSpacing: 0,
    decoration: TextDecoration.underline,
    color: baseText,
  );
}
