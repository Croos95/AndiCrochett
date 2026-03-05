import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/designs/data/models/design_model.dart';
import 'package:andicrochett/features/designs/data/repositories/design_repository.dart';

// =============================================================================
//  DesignEditorPage
//  Crear o editar un DesignDocument (solo nombre y descripción).
// =============================================================================

class DesignEditorPage extends StatefulWidget {
  const DesignEditorPage({super.key, this.existing});

  final DesignDocument? existing;

  @override
  State<DesignEditorPage> createState() => _DesignEditorPageState();
}

class _DesignEditorPageState extends State<DesignEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = DesignRepository();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final now = DateTime.now();
      final doc = DesignDocument(
        id: widget.existing?.id ?? '',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        userId: userId,
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      );
      if (_isEditing) {
        await _repo.update(doc);
      } else {
        await _repo.create(doc);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Diseño actualizado' : 'Diseño creado'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.verdeOliva,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Editar diseño \u{1FAA1}' : 'Nuevo diseño \u{1FAA1}',
          style: const TextStyle(
            fontFamily: 'Lora',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Sizes.md),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : TextButton.icon(
                    onPressed: _save,
                    icon: const Icon(
                      Icons.save_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Guardar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Sizes.lg),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _card(
                  title: '\u2728  Información del diseño',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Nombre del diseño'),
                      const SizedBox(height: Sizes.sm),
                      TextFormField(
                        controller: _nameCtrl,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'El nombre es requerido'
                            : null,
                        decoration: _inputDeco(
                          'Ej. Amigurumi de osito',
                          prefixIcon: Icons.auto_fix_high_outlined,
                        ),
                        style: const TextStyle(
                          fontSize: Sizes.fontSizeMd,
                          color: AppColors.texto,
                        ),
                      ),
                      const SizedBox(height: Sizes.md),
                      _label('Descripción (opcional)'),
                      const SizedBox(height: Sizes.sm),
                      TextFormField(
                        controller: _descCtrl,
                        minLines: 3,
                        maxLines: 6,
                        decoration: _inputDeco(
                          'Describe el diseño, materiales, nivel de dificultad...',
                        ),
                        style: const TextStyle(
                          fontSize: Sizes.fontSizeMd,
                          color: AppColors.texto,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Sizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Sizes.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textoFuerte.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: Sizes.fontSizeXl,
              fontWeight: FontWeight.bold,
              color: AppColors.textoFuerte,
              fontFamily: 'Lora',
            ),
          ),
          const Divider(color: AppColors.lino),
          const SizedBox(height: Sizes.xs),
          child,
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: Sizes.fontSizeSm,
      fontWeight: FontWeight.w600,
      color: AppColors.textoFuerte,
      letterSpacing: 0.2,
    ),
  );

  InputDecoration _inputDeco(String hint, {IconData? prefixIcon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: Sizes.fontSizeSm,
          color: AppColors.borderDark,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: AppColors.bronce)
            : null,
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sizes.md,
          vertical: Sizes.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusXl),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusXl),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusXl),
          borderSide: const BorderSide(color: AppColors.verdeOliva, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusXl),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        isDense: true,
      );
}
