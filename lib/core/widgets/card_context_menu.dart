import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';

/// Menú contextual reutilizable con opciones de Editar y Eliminar.
class CardContextMenu extends StatelessWidget {
  const CardContextMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.texto),
      splashRadius: 18,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sizes.radiusMd),
      ),
      onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: AppColors.texto),
              SizedBox(width: Sizes.sm),
              Text('Editar'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              SizedBox(width: Sizes.sm),
              Text('Eliminar', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }
}
