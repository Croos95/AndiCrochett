import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';

/// Vista genérica de estado vacío reutilizable en cualquier pantalla.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.border),
          const SizedBox(height: Sizes.md),
          Text(
            title,
            style: const TextStyle(
              fontSize: Sizes.fontSizeXl,
              fontWeight: FontWeight.bold,
              color: AppColors.textoFuerte,
            ),
          ),
          const SizedBox(height: Sizes.sm),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: Sizes.fontSizeMd,
              color: AppColors.texto,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
