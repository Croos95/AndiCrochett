import 'package:flutter/material.dart';
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
  late final TextEditingController _currentStockCtrl;
  late final TextEditingController _totalStockCtrl;

  String _category = 'Lana';
  bool _isPublic = false;
  bool _saving = false;

  static const _categories = [
    'Lana',
    'Hilo',
    'Herramientas',
    'Accesorio',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _colorCtrl = TextEditingController(text: e?.color ?? '');
    _weightCtrl = TextEditingController(text: e?.weight ?? '');
    _currentStockCtrl = TextEditingController(
      text: e != null ? e.currentStock.toString() : '',
    );
    _totalStockCtrl = TextEditingController(
      text: e != null ? e.totalStock.toString() : '',
    );
    _category = e?.category ?? 'Lana';
    _isPublic = e?.isPublic ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _colorCtrl.dispose();
    _weightCtrl.dispose();
    _currentStockCtrl.dispose();
    _totalStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final currentStock = int.parse(_currentStockCtrl.text.trim());
    final totalStock = int.parse(_totalStockCtrl.text.trim());

    ProductStatus status;
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
      currentStock: currentStock,
      totalStock: totalStock,
      status: status,
      isPublic: _isPublic,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await widget.onSave(product);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Sizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditing ? 'Editar Producto' : 'Nuevo Producto',
              style: const TextStyle(
                fontSize: Sizes.fontSizeXl,
                fontWeight: FontWeight.bold,
                color: AppColors.textoFuerte,
              ),
            ),
            const SizedBox(height: Sizes.lg),

            // Nombre
            AppInput(
              controller: _nameCtrl,
              labelText: 'Nombre del producto',
              prefixIcon: Icons.label_outline,
              validator: (v) => AppValidators.required(v, fieldName: 'El nombre'),
            ),
            const SizedBox(height: Sizes.md),

            // Categoría
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Sizes.radiusLg),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Sizes.md,
                  vertical: Sizes.sm + 4,
                ),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'Lana'),
            ),
            const SizedBox(height: Sizes.md),

            // Color (hex)
            AppInput(
              controller: _colorCtrl,
              labelText: 'Color (hex, ej: #F48FB1)',
              prefixIcon: Icons.color_lens_outlined,
            ),
            const SizedBox(height: Sizes.md),

            // Peso
            AppInput(
              controller: _weightCtrl,
              labelText: 'Peso (ej: 100g)',
              prefixIcon: Icons.scale_outlined,
            ),
            const SizedBox(height: Sizes.md),

            // Stock actual y total
            Row(
              children: [
                Expanded(
                  child: AppInput(
                    controller: _currentStockCtrl,
                    labelText: 'Stock actual',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.inventory_outlined,
                    validator: (v) =>
                        AppValidators.positiveInt(v, fieldName: 'El stock'),
                  ),
                ),
                const SizedBox(width: Sizes.md),
                Expanded(
                  child: AppInput(
                    controller: _totalStockCtrl,
                    labelText: 'Stock total',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.all_inbox_outlined,
                    validator: (v) =>
                        AppValidators.positiveInt(v, fieldName: 'El total'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.md),

            // Público
            SwitchListTile(
              title: const Text('Visible en catálogo público'),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              activeThumbColor: AppColors.verdeOliva,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: Sizes.lg),

            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.outlined(
                  label: 'Cancelar',
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: Sizes.md),
                AppButton.primary(
                  label: isEditing ? 'Actualizar' : 'Crear',
                  icon: isEditing ? Icons.save : Icons.add,
                  isLoading: _saving || widget.isSaving,
                  onPressed: _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
