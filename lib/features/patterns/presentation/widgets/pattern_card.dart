import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PatternCard
//  Tarjeta resumen de un PatternDocument en la vista de lista.
// ─────────────────────────────────────────────────────────────────────────────

class PatternCard extends StatelessWidget {
  const PatternCard({
    super.key,
    required this.pattern,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final PatternDocument pattern;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get _typeColor => pattern.type.color;

  @override
  Widget build(BuildContext context) {
    final errors = pattern.validate();
    final hasErrors = errors.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Sizes.radiusXl),
        border: Border.all(
          color: hasErrors
              ? AppColors.error.withValues(alpha: 0.45)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: hasErrors
                ? AppColors.error.withValues(alpha: 0.06)
                : AppColors.textoFuerte.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.lino.withValues(alpha: 0.5),
          highlightColor: AppColors.lino.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_typeColor.withValues(alpha: 0.8), _typeColor],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Sizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TypeBadge(
                            label: pattern.type.label,
                            color: _typeColor,
                          ),
                          const SizedBox(width: Sizes.xs),
                          _TypeBadge(
                            label: pattern.difficulty.label,
                            color: pattern.difficulty.color,
                          ),
                          if (hasErrors) ...[
                            const SizedBox(width: Sizes.xs),
                            _ErrorBadge(count: errors.length),
                          ],
                          const Spacer(),
                          _ContextMenu(onEdit: onEdit, onDelete: onDelete),
                        ],
                      ),
                      const SizedBox(height: Sizes.sm),
                      Text(
                        pattern.name.isEmpty ? '(Sin nombre)' : pattern.name,
                        style: const TextStyle(
                          fontSize: Sizes.fontSizeXl,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textoFuerte,
                          fontFamily: 'Lora',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      const Divider(color: AppColors.lino, height: Sizes.lg),
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.format_list_numbered,
                            label: '${pattern.rowCount} vueltas',
                          ),
                          const SizedBox(width: Sizes.sm),
                          _TypeBadge(
                            label: pattern.status.label,
                            color: pattern.status.color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: Sizes.fontSizeSm,
          color: color.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorBadge extends StatelessWidget {
  const _ErrorBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.sm,
        vertical: Sizes.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Sizes.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 12,
            color: AppColors.error,
          ),
          const SizedBox(width: Sizes.xs),
          Text(
            '$count error${count > 1 ? 'es' : ''}',
            style: const TextStyle(
              fontSize: Sizes.fontSizeSm,
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.texto),
        const SizedBox(width: Sizes.xs),
        Text(
          label,
          style: const TextStyle(
            fontSize: Sizes.fontSizeSm,
            color: AppColors.texto,
          ),
        ),
      ],
    );
  }
}

class _ContextMenu extends StatelessWidget {
  const _ContextMenu({required this.onEdit, required this.onDelete});
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
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: AppColors.texto),
              SizedBox(width: Sizes.sm),
              Text('Editar'),
            ],
          ),
        ),
        const PopupMenuItem(
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
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
    );
  }
}
