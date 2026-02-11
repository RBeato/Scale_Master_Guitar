import 'package:flutter/material.dart';
/// App Color Palette
/// Centralized color definitions for consistent theming across the app
class AppColors {
  // Primary background colors
  static const Color background = Color(0xFF1C2128);
  static const Color backgroundLight = Color(0xFF262C36);
  static const Color backgroundDark = Color(0xFF0D1117);

  // Surface colors (cards, dialogs, containers)
  static const Color surface = Color(0xFF262C36);
  static const Color surfaceLight = Color(0xFF30363D);

  // Border colors
  static const Color border = Color(0xFF30363D);
  static const Color borderLight = Color(0xFF444C56);

  // Accent colors
  static const Color accent = Color(0xFFEBB667); // Orange/gold accent
  static const Color accentLight = Color(0xFFF5D89A);

  // Primary action color
  static const Color primary = Colors.orange;
  static const Color primaryLight = Color(0xFFFFB74D);

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white54;

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFB74D);
}

final ThemeData appThemeData = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  visualDensity: VisualDensity.adaptivePlatformDensity,

  // Color Scheme
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: AppColors.surface,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: AppColors.textPrimary,
    onError: Colors.white,
  ),

  // AppBar Theme
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: AppColors.accent,
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
    ),
  ),

  // Drawer Theme
  drawerTheme: const DrawerThemeData(
    backgroundColor: AppColors.background,
    elevation: 20.0,
  ),

  // Card Theme
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.border, width: 1),
    ),
  ),

  // Dialog Theme
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.surface,
    elevation: 24,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    titleTextStyle: const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    contentTextStyle: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 16,
    ),
  ),

  // Bottom Sheet Theme
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
    ),
  ),

  // Elevated Button Theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),

  // Text Button Theme
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),

  // Icon Theme
  iconTheme: const IconThemeData(
    color: AppColors.accent,
    size: 24,
  ),

  // Input Decoration Theme
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    hintStyle: const TextStyle(color: AppColors.textMuted),
  ),

  // Dropdown Menu Theme
  dropdownMenuTheme: DropdownMenuThemeData(
    menuStyle: MenuStyle(
      backgroundColor: WidgetStateProperty.all(AppColors.surface),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    ),
  ),

  // SnackBar Theme
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.surface,
    contentTextStyle: const TextStyle(color: AppColors.textPrimary),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    behavior: SnackBarBehavior.floating,
  ),

  // Divider Theme
  dividerTheme: const DividerThemeData(
    color: AppColors.border,
    thickness: 1,
    space: 1,
  ),

  // Progress Indicator Theme
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primary,
    circularTrackColor: AppColors.surface,
  ),

  // Text Theme
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 50.0,
      color: AppColors.accent,
      fontWeight: FontWeight.w400,
    ),
    headlineMedium: TextStyle(
      fontSize: 20.0,
      color: AppColors.accent,
      fontWeight: FontWeight.w400,
    ),
    headlineSmall: TextStyle(
      fontSize: 18.0,
      color: Colors.white,
    ),
    titleLarge: TextStyle(fontSize: 20.0, color: Colors.white),
    titleMedium: TextStyle(fontSize: 16.0, color: Colors.white),
    titleSmall: TextStyle(
      fontSize: 12.0,
      color: AppColors.accent,
      fontWeight: FontWeight.w400,
    ),
    bodyLarge: TextStyle(
      fontSize: 16.0,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(fontSize: 16.0, color: Colors.white),
    bodySmall: TextStyle(fontSize: 12.0, color: Colors.white),
    labelLarge: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
  ),
);
