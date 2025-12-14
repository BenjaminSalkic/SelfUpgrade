import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0A0E12),
  useMaterial3: true,

  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF4EF4C0), // mint green
    secondary: Color(0xFF5AC8FA), // sky blue
    surface: Color(0xFF151920),
    surfaceContainerHighest: Color(0xFF1E2329),
    error: Color(0xFFFF6B6B),
    onPrimary: Color(0xFF0A0E12),
    onSecondary: Color(0xFF0A0E12),
    onSurface: Color(0xFFE8EAED),
    onSurfaceVariant: Color(0xFF9CA3AF),
    outline: Color(0xFF2A2F38),
  ),

  // --- Typography with better hierarchy ---
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Color(0xFFE8EAED),
      letterSpacing: -0.5,
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: Color(0xFFE8EAED),
      letterSpacing: -0.3,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: Color(0xFFE8EAED),
      letterSpacing: -0.2,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Color(0xFFE8EAED),
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Color(0xFFE8EAED),
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Color(0xFFE8EAED),
      height: 1.6,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Color(0xFFB8BBBF),
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Color(0xFF9CA3AF),
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Color(0xFFE8EAED),
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Color(0xFFB8BBBF),
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: Color(0xFF6B7280),
      letterSpacing: 0.5,
    ),
  ),

  // --- AppBar with glassmorphism effect ---
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: Color(0xFFE8EAED),
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    iconTheme: IconThemeData(
      color: Color(0xFFE8EAED),
      size: 24,
    ),
  ),

  // --- Modern Cards with subtle borders ---
  cardTheme: CardThemeData(
    color: const Color(0xFF151920),
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.black26,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: Colors.white.withOpacity(0.06),
        width: 1,
      ),
    ),
    elevation: 0,
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
  ),

  // --- Input Fields with modern styling ---
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF151920),
    hintStyle: const TextStyle(
      color: Color(0xFF6B7280),
      fontWeight: FontWeight.w400,
    ),
    labelStyle: const TextStyle(
      color: Color(0xFF9CA3AF),
      fontWeight: FontWeight.w500,
    ),
    floatingLabelStyle: const TextStyle(
      color: Color(0xFF4EF4C0),
      fontWeight: FontWeight.w500,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Colors.white.withOpacity(0.06),
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Colors.white.withOpacity(0.06),
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Color(0xFF4EF4C0),
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Color(0xFFFF6B6B),
        width: 1,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Color(0xFFFF6B6B),
        width: 2,
      ),
    ),
  ),

  // --- Elevated Buttons with gradient effect ---
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xFF2A2F38);
        }
        return const Color(0xFF4EF4C0);
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xFF6B7280);
        }
        return const Color(0xFF0A0E12);
      }),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      ),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return 0;
        return 0;
      }),
      shadowColor: WidgetStateProperty.all(
        const Color(0xFF4EF4C0).withOpacity(0.5),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
  ),

  // --- Outlined Buttons ---
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all(const Color(0xFFE8EAED)),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      ),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return const BorderSide(color: Color(0xFF4EF4C0), width: 1.5);
        }
        return BorderSide(color: Colors.white.withOpacity(0.1), width: 1);
      }),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  ),

  // --- Text Buttons ---
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all(const Color(0xFF4EF4C0)),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  ),

  // --- Icon Button ---
  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      iconColor: WidgetStateProperty.all(const Color(0xFFE8EAED)),
    ),
  ),

  // --- Floating Action Button ---
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: const Color(0xFF4EF4C0),
    foregroundColor: const Color(0xFF0A0E12),
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    extendedSizeConstraints: const BoxConstraints.tightFor(
      height: 56,
    ),
    extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
  ),

  // --- Bottom Navigation with modern styling ---
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: const Color(0xFF0A0E12),
    surfaceTintColor: Colors.transparent,
    indicatorColor: const Color(0xFF4EF4C0).withOpacity(0.15),
    indicatorShape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: Color(0xFF4EF4C0), size: 26);
      }
      return const IconThemeData(color: Color(0xFF6B7280), size: 24);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          color: Color(0xFF4EF4C0),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        );
      }
      return const TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );
    }),
    height: 70,
  ),

  // --- Divider ---
  dividerTheme: DividerThemeData(
    color: Colors.white.withOpacity(0.06),
    thickness: 1,
    space: 1,
  ),

  // --- Snackbar ---
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF1E2329),
    contentTextStyle: const TextStyle(
      color: Color(0xFFE8EAED),
      fontSize: 14,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    behavior: SnackBarBehavior.floating,
  ),
);
