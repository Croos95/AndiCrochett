import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';
import 'package:andicrochett/features/patterns/data/repositories/pattern_repository.dart';
import 'package:andicrochett/features/patterns/presentation/pages/pattern_editor_page.dart';

// =============================================================================
//  PatternDetailPage
//  Vista de solo lectura de un PatternModel.
//  – Muestra el texto de instrucción de cada vuelta con un badge de número.
//  – Muestra los errores de validación del PatternEngine en la parte superior.
//  – El botón de edición en el AppBar abre PatternEditorPage(existing: doc).
//  – Muestra una tarjeta de texto crudo cuando el patrón no puede parsearse.
// =============================================================================

class PatternDetailPage extends StatefulWidget {
  const PatternDetailPage({super.key, required this.patternId});

  final int patternId;

  @override
  State<PatternDetailPage> createState() => _PatternDetailPageState();
}

class _PatternDetailPageState extends State<PatternDetailPage> {
  // El repositorio se guarda como campo para no reinstanciarlo en cada
  // reconstrucción del widget.
  final PatternRepository _repo = PatternRepository();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<PatternModel?>(
        stream: _repo.watchById(widget.patternId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final model = snapshot.data;
          if (model == null) {
            return const Center(child: Text('Patrón no encontrado'));
          }
          return _PatternDetailContent(model: model);
        },
      ),
    );
  }
}

// ── Content widget ─────────────────────────────────────────────────────────

class _PatternDetailContent extends StatelessWidget {
  const _PatternDetailContent({required this.model});
  final PatternModel model;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Sizes.lg,
              Sizes.md,
              Sizes.lg,
              Sizes.sm,
            ),
            child: Wrap(
              spacing: Sizes.sm,
              runSpacing: Sizes.sm,
              children: [
                _MetaChip(
                  icon: Icons.category_outlined,
                  label: model.type.label,
                  color: model.type.color,
                ),
                _MetaChip(
                  icon: Icons.bar_chart,
                  label: model.difficulty.label,
                  color: model.difficulty.color,
                ),
                _MetaChip(
                  icon: model.status.icon,
                  label: model.status.label,
                  color: model.status.color,
                ),
                if (model.suggestedMaterial.isNotEmpty)
                  _MetaChip(
                    icon: Icons.texture,
                    label: model.suggestedMaterial,
                    color: AppColors.verdeOliva,
                  ),
                if (model.hookSize.isNotEmpty)
                  _MetaChip(
                    icon: Icons.straighten,
                    label: 'Gancho ${model.hookSize}',
                    color: AppColors.bronce,
                  ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Sizes.lg),
            child: Text(
              'Instrucciones',
              style: TextStyle(
                fontSize: Sizes.fontSizeXl,
                fontWeight: FontWeight.bold,
                color: AppColors.textoFuerte,
                fontFamily: 'Lora',
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Sizes.lg,
              Sizes.sm,
              Sizes.lg,
              Sizes.xxl,
            ),
            child: _RawTextCard(rawText: model.rawText),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.verdeOliva,
      foregroundColor: Colors.white,
      pinned: true,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
        title: Text(
          model.name,
          style: const TextStyle(
            fontFamily: 'Lora',
            fontWeight: FontWeight.bold,
            fontSize: Sizes.fontSizeLg,
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Editar',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PatternEditorPage(designId: model.designId, existing: model),
            ),
          ),
        ),
        const SizedBox(width: Sizes.sm),
      ],
    );
  }
}

// ── Raw text fallback card ──────────────────────────────────────────────────

class _RawTextCard extends StatelessWidget {
  const _RawTextCard({required this.rawText});
  final String rawText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Sizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Sizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Texto del patrón',
            style: TextStyle(
              fontSize: Sizes.fontSizeLg,
              fontWeight: FontWeight.bold,
              color: AppColors.textoFuerte,
            ),
          ),
          const Divider(color: AppColors.lino),
          const SizedBox(height: Sizes.xs),
          Text(
            rawText,
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: Sizes.fontSizeSm,
              color: AppColors.textoFuerte,
              fontWeight: FontWeight.w700,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small chips ─────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Sizes.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: Sizes.fontSizeSm,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
