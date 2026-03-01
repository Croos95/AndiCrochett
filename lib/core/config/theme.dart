import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.bronce,
      secondary: AppColors.verdeOliva,
      surface: AppColors.background,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.texto,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lino,
      foregroundColor: AppColors.texto,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: AppColors.textoFuerte,
        fontSize: Sizes.fontSizeXl,
        fontWeight: FontWeight.w600,
        fontFamily: 'Lora',
      ),
    ),

    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.bronce,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(Sizes.buttonHeightMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusMd),
        ),
        textStyle: const TextStyle(
          fontSize: Sizes.fontSizeLg,
          fontWeight: FontWeight.w600,
          fontFamily: 'Lora',
        ),
      ),
    ),

    // OutlinedButton
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textoFuerte,
        minimumSize: const Size.fromHeight(Sizes.buttonHeightMd),
        side: const BorderSide(color: AppColors.bronce),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusMd),
        ),
      ),
    ),

    // InputDecoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Sizes.md,
        vertical: Sizes.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Sizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Sizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Sizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.bronce, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Sizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: const TextStyle(color: AppColors.textoFuerte),
      hintStyle: TextStyle(color: AppColors.texto.withValues(alpha: 0.5)),
    ),

    // Card
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sizes.radiusLg),
      ),
      margin: const EdgeInsets.all(Sizes.sm),
    ),

    // Typography
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: AppColors.textoFuerte,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        fontFamily: 'Lora',
      ),
      titleLarge: TextStyle(
        color: AppColors.textoFuerte,
        fontSize: Sizes.fontSizeXxl,
        fontWeight: FontWeight.w600,
        fontFamily: 'Lora',
      ),
      titleMedium: TextStyle(
        color: AppColors.texto,
        fontSize: Sizes.fontSizeXl,
        fontWeight: FontWeight.w500,
        fontFamily: 'Lora',
      ),
      bodyLarge: TextStyle(
        color: AppColors.texto,
        fontSize: Sizes.fontSizeLg,
        fontFamily: 'Lora',
      ),
      bodyMedium: TextStyle(
        color: AppColors.texto,
        fontSize: Sizes.fontSizeMd,
        fontFamily: 'Lora',
      ),
      labelLarge: TextStyle(
        color: AppColors.resaltado,
        fontSize: Sizes.fontSizeMd,
        fontWeight: FontWeight.w600,
        fontFamily: 'Lora',
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),

    // Icon
    iconTheme: const IconThemeData(
      color: AppColors.verdeOliva,
      size: Sizes.iconMd,
    ),
  );
}
