import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/core/widgets/card_context_menu.dart';
import 'package:andicrochett/features/designs/data/models/design_model.dart';

// =============================================================================
//  DesignCard
//  Tarjeta resumen de un DesignModel en la cuadrícula de diseños.
// =============================================================================

class DesignCard extends StatelessWidget {
  const DesignCard({
    super.key,
    required this.design,
    required this.patternCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final DesignModel design;
  final int patternCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Sizes.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textoFuerte.withValues(alpha: 0.07),
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
              // ── Barra de acento ─────────────────────────────────────────
              Container(
                height: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.bronce, AppColors.verdeOliva],
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Sizes.sm,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bronce.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\u{1FAA1}',
                                  style: TextStyle(fontSize: 12),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Dise\u00f1o',
                                  style: TextStyle(
                                    fontSize: Sizes.fontSizeSm,
                                    color: AppColors.bronce,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          CardContextMenu(onEdit: onEdit, onDelete: onDelete),
                        ],
                      ),
                      const SizedBox(height: Sizes.sm),
                      Text(
                        design.name.isEmpty ? '(Sin nombre)' : design.name,
                        style: const TextStyle(
                          fontSize: Sizes.fontSizeXl,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textoFuerte,
                          fontFamily: 'Lora',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (design.description.isNotEmpty) ...[
                        const SizedBox(height: Sizes.xs),
                        Text(
                          design.description,
                          style: const TextStyle(
                            fontSize: Sizes.fontSizeSm,
                            color: AppColors.texto,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const Spacer(),
                      const Divider(color: AppColors.lino, height: Sizes.lg),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.verdeOliva.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome_mosaic_outlined,
                                  size: 13,
                                  color: AppColors.verdeOliva,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$patternCount patr\u00f3n${patternCount == 1 ? '' : 'es'}',
                                  style: const TextStyle(
                                    fontSize: Sizes.fontSizeSm,
                                    color: AppColors.verdeOliva,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
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
