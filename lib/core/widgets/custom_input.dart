import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';

/// Campo de texto reutilizable con estilos de marca consistentes.
class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.autofocus = false,
    this.initialValue,
    this.inputFormatters,
    this.maxLength,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool autofocus;
  final String? initialValue;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      enabled: enabled,
      autofocus: autofocus,
      validator: validator,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: const TextStyle(
        fontSize: Sizes.fontSizeMd,
        color: AppColors.texto,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        hintStyle: TextStyle(
          fontSize: Sizes.fontSizeSm,
          color: AppColors.texto.withValues(alpha: 0.5),
        ),
        labelStyle: const TextStyle(
          fontSize: Sizes.fontSizeMd,
          color: AppColors.texto,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: AppColors.texto)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sizes.md,
          vertical: Sizes.sm + 4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.lino),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.lino),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.verdeOliva, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
          borderSide: BorderSide(color: AppColors.lino.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
