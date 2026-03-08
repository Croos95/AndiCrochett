import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';

/// Barra de estadísticas rápidas del inventario.
class InventoryStatsBar extends StatelessWidget {
  const InventoryStatsBar({super.key, required this.products});

  final List<ProductModel> products;

  int get _total => products.fold(0, (s, p) => s + p.currentStock);
  int get _lowStock =>
      products.where((p) => p.status == 'low_stock' || p.status == 'out_of_stock').length;
  int get _full => products.where((p) => p.status == 'full').length;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Sizes.lg,
            vertical: Sizes.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            border: const Border(
              bottom: BorderSide(color: AppColors.lino, width: 1),
            ),
          ),
          child: Wrap(
            spacing: Sizes.lg,
            runSpacing: Sizes.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatItem(
                label: 'PRODUCTOS:',
                value: '${products.length}',
                valueColor: AppColors.verdeOliva,
              ),
              if (!isMobile) _statDivider(),
              _StatItem(
                label: 'TOTAL STOCK:',
                value: '$_total',
                valueColor: AppColors.verdeOliva,
              ),
              if (!isMobile) _statDivider(),
              _StatItem(
                label: 'LLENOS:',
                value: '$_full',
                valueColor: AppColors.success,
              ),
              if (!isMobile) _statDivider(),
              _StatItem(
                label: 'BAJO STOCK:',
                value: '$_lowStock',
                valueColor: _lowStock > 0 ? AppColors.error : AppColors.texto,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: Sizes.lg),
      color: AppColors.lino,
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.texto,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: Sizes.sm),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
