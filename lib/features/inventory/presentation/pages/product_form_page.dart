import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';

/// Formulario para crear / editar un producto.
///
/// Si [product] es `null` se usa como formulario de creación.
class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.product});

  final ProductModel? product;

  bool get isEditing => product != null;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _currentStockCtrl;
  late final TextEditingController _totalStockCtrl;

  String _selectedCategory = 'Madeja';
  bool _isPublic = true;

  static const _categories = [
    'Madeja',
    'Ovillo',
    'Hilo',
    'Herramientas',
    'Accesorios',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _weightCtrl = TextEditingController(text: p?.weight ?? '');
    _colorCtrl = TextEditingController(text: p?.colorHex ?? '#');
    _currentStockCtrl =
        TextEditingController(text: p != null ? '${p.currentStock}' : '');
    _totalStockCtrl =
        TextEditingController(text: p != null ? '${p.totalStock}' : '');
    _selectedCategory = p?.category ?? 'Madeja';
    _isPublic = p?.isPublic ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _colorCtrl.dispose();
    _currentStockCtrl.dispose();
    _totalStockCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: guardar en Firestore / provider
    final newProduct = ProductModel(
      id: widget.product?.id ?? '',
      name: _nameCtrl.text.trim(),
      category: _selectedCategory,
      colorHex: _colorCtrl.text.trim(),
      weight: _weightCtrl.text.trim(),
      currentStock: int.tryParse(_currentStockCtrl.text) ?? 0,
      totalStock: int.tryParse(_totalStockCtrl.text) ?? 0,
      status: _computeStatus(),
      isPublic: _isPublic,
    );

    Navigator.of(context).pop(newProduct);
  }

  String _computeStatus() {
    final current = int.tryParse(_currentStockCtrl.text) ?? 0;
    final total = int.tryParse(_totalStockCtrl.text) ?? 1;
    if (current == 0) return 'out_of_stock';
    if (current == total) return 'full';
    if (current / total <= 0.2) return 'low_stock';
    return 'available';
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.verdeOliva,
        foregroundColor: Colors.white,
        title: Text(widget.isEditing ? 'Editar producto' : 'Nuevo producto'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text(
              'Guardar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Sizes.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Imagen placeholder ──
                  _ImagePicker(
                    imageUrl: widget.product?.imageUrl,
                  ),
                  const SizedBox(height: Sizes.lg),

                  // ── Nombre ──
                  _buildLabel('Nombre del producto'),
                  const SizedBox(height: Sizes.xs),
                  _StyledTextFormField(
                    controller: _nameCtrl,
                    hint: 'Ej: Lana Merino Rosa',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: Sizes.md),

                  // ── Categoría ──
                  _buildLabel('Categoría'),
                  const SizedBox(height: Sizes.xs),
                  _StyledDropdown(
                    value: _selectedCategory,
                    items: _categories,
                    onChanged: (v) =>
                        setState(() => _selectedCategory = v ?? _selectedCategory),
                  ),
                  const SizedBox(height: Sizes.md),

                  // ── Color + Peso ──
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Color (hex)'),
                            const SizedBox(height: Sizes.xs),
                            _StyledTextFormField(
                              controller: _colorCtrl,
                              hint: '#F48FB1',
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Requerido';
                                }
                                if (!RegExp(r'^#[0-9A-Fa-f]{6}$')
                                    .hasMatch(v.trim())) {
                                  return 'Formato: #RRGGBB';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Sizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Peso'),
                            const SizedBox(height: Sizes.xs),
                            _StyledTextFormField(
                              controller: _weightCtrl,
                              hint: '100g',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Requerido'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sizes.md),

                  // ── Stock actual + total ──
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Stock actual'),
                            const SizedBox(height: Sizes.xs),
                            _StyledTextFormField(
                              controller: _currentStockCtrl,
                              hint: '0',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Requerido';
                                }
                                if (int.tryParse(v.trim()) == null) {
                                  return 'Número válido';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Sizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Stock total'),
                            const SizedBox(height: Sizes.xs),
                            _StyledTextFormField(
                              controller: _totalStockCtrl,
                              hint: '50',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Requerido';
                                }
                                if (int.tryParse(v.trim()) == null) {
                                  return 'Número válido';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sizes.lg),

                  // ── Público ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Sizes.md,
                      vertical: Sizes.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Sizes.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Visible en catálogo público',
                        style: TextStyle(
                          fontSize: Sizes.fontSizeMd,
                          color: AppColors.textoFuerte,
                        ),
                      ),
                      subtitle: Text(
                        _isPublic
                            ? 'Los clientes podrán ver este producto'
                            : 'Solo tú verás este producto',
                        style: const TextStyle(
                          fontSize: Sizes.fontSizeSm,
                          color: AppColors.texto,
                        ),
                      ),
                      value: _isPublic,
                      activeColor: AppColors.verdeOliva,
                      onChanged: (v) => setState(() => _isPublic = v),
                    ),
                  ),
                  const SizedBox(height: Sizes.xl),

                  // ── Submit ──
                  SizedBox(
                    height: Sizes.buttonHeightLg,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.verdeOliva,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Sizes.radiusLg),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        widget.isEditing
                            ? 'Actualizar producto'
                            : 'Crear producto',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: Sizes.fontSizeLg,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Sizes.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── helpers ─────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: Sizes.fontSizeSm,
        fontWeight: FontWeight.w600,
        color: AppColors.textoFuerte,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Sub-widgets del formulario
// ═══════════════════════════════════════════════════════════════════════════

class _StyledTextFormField extends StatelessWidget {
  const _StyledTextFormField({
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: Sizes.fontSizeMd),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: Sizes.fontSizeSm,
          color: AppColors.texto.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.lino),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.lino),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.verdeOliva, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sizes.md,
          vertical: Sizes.sm + 2,
        ),
      ),
    );
  }
}

class _StyledDropdown extends StatelessWidget {
  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Sizes.radiusLg),
        border: Border.all(color: AppColors.lino),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: AppColors.texto),
          style: const TextStyle(
            fontSize: Sizes.fontSizeMd,
            color: AppColors.textoFuerte,
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        // TODO: seleccionar imagen
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
          border: Border.all(
            color: AppColors.lino,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(Sizes.radiusLg - 1),
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 40,
                      color: AppColors.texto.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: Sizes.sm),
                    Text(
                      'Agregar imagen',
                      style: TextStyle(
                        fontSize: Sizes.fontSizeSm,
                        color: AppColors.texto.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
