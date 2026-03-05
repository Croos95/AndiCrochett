import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';

/// Tabla de productos reutilizable.
class ProductTable extends StatelessWidget {
  const ProductTable({
    super.key,
    required this.products,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final List<ProductModel> products;
  final ValueChanged<ProductModel> onTap;
  final ValueChanged<ProductModel>? onEdit;
  final ValueChanged<ProductModel>? onDelete;

  Color _statusColor(String status) => switch (status) {
        'available' => AppColors.success,
        'full' => AppColors.success,
        'low_stock' => AppColors.error,
        'reorder' => AppColors.warning,
        'out_of_stock' => AppColors.error,
        _ => AppColors.texto,
      };

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.lino),
        borderRadius: BorderRadius.circular(Sizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.border,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Sizes.radiusXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Sizes.lg,
                vertical: Sizes.md,
              ),
              decoration: const BoxDecoration(
                color: AppColors.lino,
                border: Border(
                  bottom: BorderSide(color: AppColors.lino),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: _HeaderCell('PRODUCTO')),
                  Expanded(flex: 1, child: _HeaderCell('CATEGORÍA')),
                  Expanded(flex: 2, child: _HeaderCell('COLOR')),
                  Expanded(flex: 1, child: _HeaderCell('PESO')),
                  Expanded(flex: 2, child: _HeaderCell('ESTADO')),
                  Expanded(flex: 2, child: _HeaderCell('STOCK')),
                  SizedBox(width: 48),
                ],
              ),
            ),
            // Rows
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  return _ProductRow(
                    product: p,
                    statusColor: _statusColor(p.status),
                    productColor: _hexToColor(p.colorHex),
                    onTap: () => onTap(p),
                    onEdit: onEdit != null ? () => onEdit!(p) : null,
                    onDelete: onDelete != null ? () => onDelete!(p) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header cell ──────────────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: AppColors.textoFuerte,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Product row ──────────────────────────────────────────────────────────────

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.statusColor,
    required this.productColor,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final ProductModel product;
  final Color statusColor;
  final Color productColor;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: AppColors.lino,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Sizes.lg,
          vertical: Sizes.md,
        ),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: AppColors.lino, width: 0.5)),
        ),
        child: Row(
          children: [
            // Product name + thumbnail
            Expanded(
              flex: 3,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: productColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(Sizes.radiusMd),
                        border: Border.all(color: AppColors.lino),
                      ),
                      child: product.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(Sizes.radiusMd),
                              child: Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.inventory_2_rounded,
                              size: 20,
                              color: productColor,
                            ),
                    ),
                    const SizedBox(width: Sizes.md),
                    SizedBox(
                      width: 120,
                      child: Text(
                        product.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: Sizes.fontSizeMd,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textoFuerte,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Category
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  product.category,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: Sizes.fontSizeSm,
                    color: AppColors.texto,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Color
            Expanded(
              flex: 2,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: productColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.lino),
                      ),
                    ),
                    const SizedBox(width: Sizes.sm),
                    Text(
                      product.colorHex,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: Sizes.fontSizeSm,
                        color: AppColors.texto,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Weight
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  product.weight,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: Sizes.fontSizeSm,
                    color: AppColors.texto,
                  ),
                ),
              ),
            ),
            // Status
            Expanded(
              flex: 2,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: Sizes.sm),
                    Text(
                      product.statusLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Stock bar
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: Sizes.fontSizeSm,
                        fontWeight: FontWeight.bold,
                        color: AppColors.texto,
                      ),
                      children: [
                        TextSpan(text: '${product.currentStock} '),
                        TextSpan(
                          text: '/ ${product.totalStock}',
                          style: const TextStyle(color: AppColors.texto),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: product.stockRatio,
                      minHeight: 4,
                      backgroundColor: AppColors.lino,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            SizedBox(
              width: 48,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: AppColors.texto),
                iconSize: 20,
                splashRadius: 20,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Sizes.radiusLg),
                ),
                onSelected: (action) {
                  switch (action) {
                    case 'detail':
                      onTap();
                    case 'edit':
                      onEdit?.call();
                    case 'delete':
                      onDelete?.call();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'detail',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 18, color: AppColors.texto),
                        SizedBox(width: 8),
                        Text('Ver detalle'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: AppColors.texto),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18,
                              color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Eliminar',
                              style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
