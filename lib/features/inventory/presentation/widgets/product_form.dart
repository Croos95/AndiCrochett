import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/core/utils/validators.dart';
import 'package:andicrochett/core/widgets/custom_button.dart';
import 'package:andicrochett/core/widgets/custom_input.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';

/// Formulario para crear o editar un [ProductModel].
///
/// Si se pasa [existing], el formulario se pre-llena para modo edición.
/// [onSave] se invoca con el modelo resultante al enviar.
class ProductForm extends StatefulWidget {
  const ProductForm({
    super.key,
    this.existing,
    required this.onSave,
    this.isSaving = false,
  });

  final ProductModel? existing;
  final Future<void> Function(ProductModel product) onSave;
  final bool isSaving;

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _currentStockCtrl;
  late final TextEditingController _totalStockCtrl;

  String _category = 'Estambre';
  bool _saving = false;
  bool _isDirty = false;
  Color? _colorPreview;

  static const _categories = [
    'Estambre',
    'Hilo',
    'Agujas y Ganchos',
    'Herramientas',
    'Accesorios',
    'Botones',
    'Relleno',
    'Otro',
  ];

  static const Map<String, IconData> _categoryIcons = {
    'Estambre': Icons.adjust,
    'Hilo': Icons.linear_scale,
    'Agujas y Ganchos': Icons.create,
    'Herramientas': Icons.build,
    'Accesorios': Icons.stars,
    'Botones': Icons.radio_button_unchecked,
    'Relleno': Icons.cloud,
    'Otro': Icons.category,
  };

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _colorCtrl = TextEditingController(text: e?.color ?? '');
    _weightCtrl = TextEditingController(text: e?.weight ?? '');
    _brandCtrl = TextEditingController(text: e?.brand ?? '');
    _currentStockCtrl = TextEditingController(
      text: e != null ? e.currentStock.toString() : '',
    );
    _totalStockCtrl = TextEditingController(
      text: e != null ? e.totalStock.toString() : '',
    );
    _category = e?.category ?? 'Estambre';
    _colorPreview = _parseColor(e?.color);

    _colorCtrl.addListener(() {
      final parsed = _parseColor(_colorCtrl.text);
      if (parsed != _colorPreview) setState(() => _colorPreview = parsed);
      _markDirty();
    });
    _nameCtrl.addListener(_markDirty);
    _weightCtrl.addListener(_markDirty);
    _brandCtrl.addListener(_markDirty);
    _currentStockCtrl.addListener(_markDirty);
    _totalStockCtrl.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) return null;
    final h = hex.trim().replaceFirst('#', '');
    if (h.length == 6) {
      final val = int.tryParse('FF$h', radix: 16);
      if (val != null) return Color(val);
    }
    return null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _colorCtrl.dispose();
    _weightCtrl.dispose();
    _brandCtrl.dispose();
    _currentStockCtrl.dispose();
    _totalStockCtrl.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Descartar cambios?'),
            content: const Text(
              'Tienes cambios sin guardar. ¿Deseas salir sin guardar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Continuar editando'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Descartar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa los campos marcados antes de continuar'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final currentStock = int.parse(_currentStockCtrl.text.trim());
    final totalStock = int.parse(_totalStockCtrl.text.trim());

    // Cross-field validation (double-check beyond inline validator)
    if (currentStock > totalStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El stock actual no puede superar el stock total'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final ProductStatus status;
    if (currentStock == 0) {
      status = ProductStatus.outOfStock;
    } else if (currentStock <= (totalStock * 0.2).ceil()) {
      status = ProductStatus.lowStock;
    } else {
      status = ProductStatus.available;
    }

    final product = ProductModel(
      id: widget.existing?.id ?? '',
      userId: widget.existing?.userId ?? '',
      name: _nameCtrl.text.trim(),
      imageUrl: widget.existing?.imageUrl ?? '',
      category: _category,
      color: _colorCtrl.text.trim(),
      weight: _weightCtrl.text.trim(),
      brand: _brandCtrl.text.trim(),
      currentStock: currentStock,
      totalStock: totalStock,
      status: status,
      isPublic: widget.existing?.isPublic ?? false,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await widget.onSave(product);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final isBusy = _saving || widget.isSaving;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirm = await _confirmDiscard();
        if (confirm && mounted) Navigator.pop(context);
      },
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Sizes.lg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 480;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // -- Header --------------------------------------------------
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.verdeOliva.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(Sizes.radiusMd),
                        ),
                        child: Icon(
                          isEditing
                              ? Icons.edit_outlined
                              : Icons.add_box_outlined,
                          color: AppColors.verdeOliva,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: Sizes.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Editar Producto' : 'Nuevo Producto',
                              style: const TextStyle(
                                fontSize: Sizes.fontSizeXl,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textoFuerte,
                              ),
                            ),
                            Text(
                              isEditing
                                  ? 'Modifica los datos del producto'
                                  : 'Completa los datos para registrar',
                              style: TextStyle(
                                fontSize: Sizes.fontSizeSm,
                                color: AppColors.textoFuerte.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sizes.md),
                  const Divider(height: 1),
                  const SizedBox(height: Sizes.lg),

                  // -- Información básica -----------------------------------
                  const _SectionLabel(label: 'Información básica'),
                  const SizedBox(height: Sizes.sm),

                  AppInput(
                    controller: _nameCtrl,
                    labelText: 'Nombre del producto *',
                    hintText: 'Ej: Estambre grueso morado',
                    prefixIcon: Icons.label_outline,
                    textInputAction: TextInputAction.next,
                    autofocus: !isEditing,
                    validator: (v) =>
                        AppValidators.required(v, fieldName: 'El nombre'),
                  ),
                  const SizedBox(height: Sizes.md),

                  AppInput(
                    controller: _brandCtrl,
                    labelText: 'Marca',
                    hintText: 'Ej: Caron, Lion Brand, Omega',
                    prefixIcon: Icons.business_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: Sizes.md),

                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: InputDecoration(
                      labelText: 'Categoría *',
                      prefixIcon: const Icon(
                        Icons.category_outlined,
                        size: 20,
                        color: AppColors.texto,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Sizes.radiusLg),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Sizes.radiusLg),
                        borderSide: const BorderSide(color: AppColors.lino),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Sizes.radiusLg),
                        borderSide: const BorderSide(
                          color: AppColors.verdeOliva,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Sizes.md,
                        vertical: Sizes.sm + 4,
                      ),
                    ),
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                Icon(
                                  _categoryIcons[c] ?? Icons.category,
                                  size: 16,
                                  color: AppColors.verdeOliva,
                                ),
                                const SizedBox(width: Sizes.sm),
                                Text(c),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _category = v ?? 'Estambre';
                      _isDirty = true;
                    }),
                  ),
                  const SizedBox(height: Sizes.md),

                  // Color con preview visual
                  AppInput(
                    controller: _colorCtrl,
                    labelText: 'Color (hex)',
                    hintText: '#F48FB1',
                    prefixIcon: Icons.color_lens_outlined,
                    textInputAction: TextInputAction.next,
                    maxLength: 7,
                    suffixIcon: _colorPreview != null
                        ? Padding(
                            padding: const EdgeInsets.all(10),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _colorPreview,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black12,
                                  width: 1,
                                ),
                              ),
                            ),
                          )
                        : null,
                    validator: AppValidators.optionalHexColor,
                  ),
                  const SizedBox(height: Sizes.md),

                  AppInput(
                    controller: _weightCtrl,
                    labelText: 'Peso',
                    hintText: 'Ej: 100g, 200g',
                    prefixIcon: Icons.scale_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: Sizes.lg),

                  // -- Stock -----------------------------------------------
                  const _SectionLabel(label: 'Stock'),
                  const SizedBox(height: Sizes.sm),

                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildCurrentStockField()),
                        const SizedBox(width: Sizes.md),
                        Expanded(child: _buildTotalStockField()),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildCurrentStockField(),
                        const SizedBox(height: Sizes.md),
                        _buildTotalStockField(),
                      ],
                    ),
                  const SizedBox(height: Sizes.sm),

                  // Indicador de estado calculado
                  _StockStatusHint(
                    currentText: _currentStockCtrl.text,
                    totalText: _totalStockCtrl.text,
                  ),
                  const SizedBox(height: Sizes.lg),

                  // -- Botones ---------------------------------------------
                  if (isWide)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton.outlined(
                          label: 'Cancelar',
                          onPressed: isBusy
                              ? null
                              : () async {
                                  if (await _confirmDiscard()) {
                                    if (mounted) Navigator.pop(context);
                                  }
                                },
                        ),
                        const SizedBox(width: Sizes.md),
                        AppButton.primary(
                          label: isEditing ? 'Actualizar' : 'Crear producto',
                          icon: isEditing ? Icons.save_outlined : Icons.add,
                          isLoading: isBusy,
                          onPressed: isBusy ? null : _submit,
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppButton.primary(
                          label: isEditing ? 'Actualizar' : 'Crear producto',
                          icon: isEditing ? Icons.save_outlined : Icons.add,
                          isLoading: isBusy,
                          onPressed: isBusy ? null : _submit,
                          width: double.infinity,
                        ),
                        const SizedBox(height: Sizes.sm),
                        AppButton.outlined(
                          label: 'Cancelar',
                          onPressed: isBusy
                              ? null
                              : () async {
                                  if (await _confirmDiscard()) {
                                    if (mounted) Navigator.pop(context);
                                  }
                                },
                          width: double.infinity,
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStockField() {
    return AppInput(
      controller: _currentStockCtrl,
      labelText: 'Stock actual *',
      hintText: '0',
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      prefixIcon: Icons.inventory_outlined,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) =>
          AppValidators.nonNegativeInt(v, fieldName: 'El stock actual'),
    );
  }

  Widget _buildTotalStockField() {
    return AppInput(
      controller: _totalStockCtrl,
      labelText: 'Stock total *',
      hintText: '10',
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      prefixIcon: Icons.all_inbox_outlined,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) {
        final base = AppValidators.positiveInt(v, fieldName: 'El stock total');
        if (base != null) return base;
        final curr = int.tryParse(_currentStockCtrl.text.trim()) ?? 0;
        final total = int.parse(v!.trim());
        if (curr > total) {
          return 'El total debe ser >= al stock actual ($curr)';
        }
        return null;
      },
    );
  }
}

// -- Helpers -------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.verdeOliva,
        letterSpacing: 0.8,
      ),
    );
  }
}

/// Muestra el estado que se calculará en función de los valores de stock.
class _StockStatusHint extends StatelessWidget {
  const _StockStatusHint({required this.currentText, required this.totalText});
  final String currentText;
  final String totalText;

  @override
  Widget build(BuildContext context) {
    final curr = int.tryParse(currentText.trim());
    final total = int.tryParse(totalText.trim());
    if (curr == null || total == null || total <= 0) return const SizedBox();

    final ProductStatus status;
    final Color color;
    if (curr == 0) {
      status = ProductStatus.outOfStock;
      color = AppColors.error;
    } else if (curr <= (total * 0.2).ceil()) {
      status = ProductStatus.lowStock;
      color = AppColors.resaltado;
    } else {
      status = ProductStatus.available;
      color = AppColors.verdeOliva;
    }

    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 6),
        Text(
          'Estado resultante: ${status.label}',
          style: TextStyle(
            fontSize: Sizes.fontSizeSm,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
