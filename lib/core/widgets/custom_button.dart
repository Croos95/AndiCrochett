import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';

/// Botón reutilizable con variantes de marca.
///
/// Uso:
/// ```dart
/// AppButton.primary(label: 'Guardar', onPressed: _save)
/// AppButton.secondary(label: 'Cancelar', onPressed: _cancel)
/// AppButton.danger(label: 'Eliminar', onPressed: _delete)
/// AppButton.outlined(label: 'Ver más', onPressed: _more)
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.height = Sizes.buttonHeightMd,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double height;

  // ── Constructores nombrados ─────────────────────────────────────────────

  factory AppButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width,
  }) => AppButton(
    key: key,
    label: label,
    onPressed: onPressed,
    icon: icon,
    isLoading: isLoading,
    width: width,
    backgroundColor: AppColors.verdeOliva,
    foregroundColor: Colors.white,
  );

  factory AppButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width,
  }) => AppButton(
    key: key,
    label: label,
    onPressed: onPressed,
    icon: icon,
    isLoading: isLoading,
    width: width,
    backgroundColor: AppColors.resaltado,
    foregroundColor: Colors.white,
  );

  factory AppButton.danger({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width,
  }) => AppButton(
    key: key,
    label: label,
    onPressed: onPressed,
    icon: icon,
    isLoading: isLoading,
    width: width,
    backgroundColor: AppColors.error,
    foregroundColor: Colors.white,
  );

  factory AppButton.outlined({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width,
  }) => AppButton(
    key: key,
    label: label,
    onPressed: onPressed,
    icon: icon,
    isLoading: isLoading,
    width: width,
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.verdeOliva,
    borderColor: AppColors.verdeOliva,
  );

  @override
  Widget build(BuildContext context) {
    final child = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: borderColor != null ? 0 : 1,
        padding: const EdgeInsets.symmetric(horizontal: Sizes.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
          side: borderColor != null
              ? BorderSide(color: borderColor!)
              : BorderSide.none,
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foregroundColor,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: Sizes.sm),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: Sizes.fontSizeMd,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );

    if (width != null) {
      return SizedBox(height: height, width: width, child: child);
    }
    return IntrinsicWidth(
      child: SizedBox(height: height, child: child),
    );
  }
}
