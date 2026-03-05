import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';
import 'package:andicrochett/features/inventory/presentation/pages/product_form_page.dart';

/// Pagina de detalle de un producto.
///
/// Retorna via Navigator.pop:
///   - null  -> sin cambios
///   - ProductModel con id vacio  -> se elimino
///   - ProductModel con datos     -> se edito / ajusto stock
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final ProductModel product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late ProductModel _product;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  // -- helpers --

  Color _statusColor() => switch (_product.status) {
        'available' || 'full' => AppColors.success,
        'low_stock' || 'reorder' => AppColors.warning,
        'out_of_stock' => AppColors.error,
        _ => AppColors.texto,
      };

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _computeStatus(int current, int total) {
    if (current == 0) return 'out_of_stock';
    if (current == total) return 'full';
    if (total > 0 && current / total <= 0.2) return 'low_stock';
    return 'available';
  }

  // -- acciones --

  Future<void> _openEdit() async {
    final result = await Navigator.of(context).push<ProductModel>(
      MaterialPageRoute(
        builder: (_) => ProductFormPage(product: _product),
      ),
    );
    if (result != null) {
      setState(() {
        _product = result;
        _hasChanges = true;
      });
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
        ),
        title: const Text('Eliminar producto'),
        content: Text(
          'Seguro que deseas eliminar "${_product.name}"?\nEsta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // cerrar dialog
              // devolver un producto con id vacio = senal de eliminacion
              Navigator.of(context).pop(
                _product.copyWith(id: ''),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showStockAdjustSheet() {
    int tempStock = _product.currentStock;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(Sizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: Sizes.lg),
              Text(
                'Ajustar stock de ${_product.name}',
                style: const TextStyle(
                  fontSize: Sizes.fontSizeXl,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textoFuerte,
                ),
              ),
              const SizedBox(height: Sizes.sm),
              Text(
                'Total: ${_product.totalStock}',
                style: const TextStyle(
                  fontSize: Sizes.fontSizeSm,
                  color: AppColors.texto,
                ),
              ),
              const SizedBox(height: Sizes.lg),
              // stepper
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundIconButton(
                    icon: Icons.remove,
                    onPressed: tempStock > 0
                        ? () => setSheetState(() => tempStock--)
                        : null,
                  ),
                  const SizedBox(width: Sizes.xl),
                  SizedBox(
                    width: 80,
                    child: Text(
                      '$tempStock',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textoFuerte,
                        fontFamily: 'Lora',
                      ),
                    ),
                  ),
                  const SizedBox(width: Sizes.xl),
                  _RoundIconButton(
                    icon: Icons.add,
                    onPressed: tempStock < _product.totalStock
                        ? () => setSheetState(() => tempStock++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: Sizes.sm),
              // barra visual
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Sizes.xl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _product.totalStock > 0
                        ? tempStock / _product.totalStock
                        : 0,
                    minHeight: 8,
                    backgroundColor: AppColors.lino,
                    color: _statusColor(),
                  ),
                ),
              ),
              const SizedBox(height: Sizes.lg),
              // guardar
              SizedBox(
                width: double.infinity,
                height: Sizes.buttonHeightLg,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _product = _product.copyWith(
                        currentStock: tempStock,
                        status: _computeStatus(tempStock, _product.totalStock),
                      );
                      _hasChanges = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdeOliva,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Sizes.radiusLg),
                    ),
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: Sizes.md),
            ],
          ),
        ),
      ),
    );
  }

  // -- build --

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final productColor = _hexToColor(_product.colorHex);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_hasChanges ? _product : null);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return CustomScrollView(
              slivers: [
                // -- App bar --
                SliverAppBar(
                  expandedHeight: isWide ? 220 : 180,
                  pinned: true,
                  backgroundColor: AppColors.verdeOliva,
                  foregroundColor: Colors.white,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context)
                        .pop(_hasChanges ? _product : null),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      tooltip: 'Editar',
                      onPressed: _openEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Eliminar',
                      onPressed: _confirmDelete,
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      _product.name,
                      style: const TextStyle(
                        fontFamily: 'Lora',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.verdeOliva,
                            productColor.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _categoryIcon(_product.category),
                          size: 72,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
                ),

                // -- Body --
                SliverPadding(
                  padding: EdgeInsets.all(isWide ? Sizes.xl : Sizes.md),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Status chip
                      _StatusChip(
                        label: _product.statusLabel,
                        color: statusColor,
                      ),
                      const SizedBox(height: Sizes.lg),

                      // Info cards
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: _buildInfoCard(productColor)),
                            const SizedBox(width: Sizes.md),
                            Expanded(
                                child: _buildStockCard(statusColor)),
                          ],
                        )
                      else ...[
                        _buildInfoCard(productColor),
                        const SizedBox(height: Sizes.md),
                        _buildStockCard(statusColor),
                      ],

                      const SizedBox(height: Sizes.lg),
                      _buildVisibilityCard(),
                      const SizedBox(height: Sizes.lg),
                      _buildActionsSection(),
                      const SizedBox(height: Sizes.xl),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // -- Cards --

  Widget _buildInfoCard(Color productColor) {
    return _DetailCard(
      title: 'Informacion',
      icon: Icons.info_outline_rounded,
      children: [
        _DetailRow(label: 'Categoria', value: _product.category),
        _DetailRow(
          label: 'Color',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: productColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
              ),
              const SizedBox(width: Sizes.sm),
              Text(
                _product.colorHex,
                style: const TextStyle(
                  fontSize: Sizes.fontSizeMd,
                  color: AppColors.textoFuerte,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        _DetailRow(label: 'Peso', value: _product.weight),
      ],
    );
  }

  Widget _buildStockCard(Color statusColor) {
    return _DetailCard(
      title: 'Stock',
      icon: Icons.inventory_rounded,
      children: [
        _DetailRow(label: 'Actual', value: '${_product.currentStock}'),
        _DetailRow(label: 'Total', value: '${_product.totalStock}'),
        const SizedBox(height: Sizes.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _product.stockRatio,
            minHeight: 10,
            backgroundColor: AppColors.lino,
            color: statusColor,
          ),
        ),
        const SizedBox(height: Sizes.xs),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(_product.stockRatio * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: Sizes.fontSizeSm,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityCard() {
    return _DetailCard(
      title: 'Visibilidad',
      icon: Icons.visibility_rounded,
      children: [
        Row(
          children: [
            Icon(
              _product.isPublic
                  ? Icons.public_rounded
                  : Icons.lock_outline_rounded,
              size: 20,
              color:
                  _product.isPublic ? AppColors.success : AppColors.texto,
            ),
            const SizedBox(width: Sizes.sm),
            Text(
              _product.isPublic
                  ? 'Visible en catalogo publico'
                  : 'Oculto del catalogo publico',
              style: const TextStyle(
                fontSize: Sizes.fontSizeMd,
                color: AppColors.textoFuerte,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Wrap(
      spacing: Sizes.md,
      runSpacing: Sizes.sm,
      children: [
        _ActionButton(
          label: 'Editar producto',
          icon: Icons.edit_rounded,
          color: AppColors.verdeOliva,
          onPressed: _openEdit,
        ),
        _ActionButton(
          label: 'Ajustar stock',
          icon: Icons.tune_rounded,
          color: AppColors.resaltado,
          onPressed: _showStockAdjustSheet,
        ),
        _ActionButton(
          label: 'Eliminar',
          icon: Icons.delete_outline_rounded,
          color: AppColors.error,
          outlined: true,
          onPressed: _confirmDelete,
        ),
      ],
    );
  }

  IconData _categoryIcon(String cat) => switch (cat.toLowerCase()) {
        'madeja' => Icons.circle,
        'ovillo' => Icons.circle_outlined,
        'herramientas' => Icons.handyman_rounded,
        _ => Icons.inventory_2_rounded,
      };
}

// ========================================================================
//  Sub-widgets reutilizables dentro de esta pagina
// ========================================================================

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Sizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textoFuerte),
              const SizedBox(width: Sizes.sm),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Sizes.fontSizeLg,
                  color: AppColors.textoFuerte,
                ),
              ),
            ],
          ),
          const SizedBox(height: Sizes.md),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, this.value, this.trailing});
  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: Sizes.fontSizeMd,
              color: AppColors.texto,
            ),
          ),
          trailing ??
              Text(
                value ?? '',
                style: const TextStyle(
                  fontSize: Sizes.fontSizeMd,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textoFuerte,
                ),
              ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.outlined = false,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Sizes.radiusLg),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Sizes.md,
            vertical: Sizes.sm,
          ),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Sizes.md,
          vertical: Sizes.sm,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: enabled ? AppColors.lino : AppColors.lino.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: enabled
                ? AppColors.textoFuerte
                : AppColors.texto.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
