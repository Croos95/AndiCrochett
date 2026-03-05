import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/designs/data/models/design_model.dart';
import 'package:andicrochett/features/designs/data/repositories/design_repository.dart';
import 'package:andicrochett/features/designs/presentation/pages/design_editor_page.dart';
import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';
import 'package:andicrochett/features/patterns/data/repositories/pattern_repository.dart';
import 'package:andicrochett/features/patterns/presentation/pages/pattern_detail_page.dart';
import 'package:andicrochett/features/patterns/presentation/pages/pattern_editor_page.dart';
import 'package:andicrochett/features/patterns/presentation/widgets/pattern_card.dart';

// =============================================================================
//  DesignDetailPage
//  Shows a design's information and the list of patterns that belong to it.
// =============================================================================

class DesignDetailPage extends StatefulWidget {
  const DesignDetailPage({super.key, required this.designId});

  final String designId;

  @override
  State<DesignDetailPage> createState() => _DesignDetailPageState();
}

class _DesignDetailPageState extends State<DesignDetailPage> {
  final _designRepo = DesignRepository();
  final _patternRepo = PatternRepository();

  void _openPatternEditor({PatternDocument? existing}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PatternEditorPage(designId: widget.designId, existing: existing),
      ),
    );
  }

  void _openPatternDetail(PatternDocument pattern) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatternDetailPage(patternId: pattern.id),
      ),
    );
  }

  Future<void> _confirmDeletePattern(PatternDocument pattern) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
        ),
        title: const Text('Eliminar patrón'),
        content: Text(
          '¿Eliminar "${pattern.name}"? Esta acción es irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _patternRepo.delete(pattern.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Patrón eliminado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DesignDocument?>(
      stream: _designRepo.watchById(widget.designId),
      builder: (context, designSnap) {
        if (designSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final design = designSnap.data;
        if (design == null) {
          return const Scaffold(
            body: Center(child: Text('Diseño no encontrado')),
          );
        }
        return _DesignDetailContent(
          design: design,
          patternRepo: _patternRepo,
          onAddPattern: () => _openPatternEditor(),
          onEditPattern: (p) => _openPatternEditor(existing: p),
          onDeletePattern: _confirmDeletePattern,
          onTapPattern: _openPatternDetail,
          onEditDesign: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DesignEditorPage(existing: design),
            ),
          ),
        );
      },
    );
  }
}

// ── Content ────────────────────────────────────────────────────────────────

class _DesignDetailContent extends StatelessWidget {
  const _DesignDetailContent({
    required this.design,
    required this.patternRepo,
    required this.onAddPattern,
    required this.onEditPattern,
    required this.onDeletePattern,
    required this.onTapPattern,
    required this.onEditDesign,
  });

  final DesignDocument design;
  final PatternRepository patternRepo;
  final VoidCallback onAddPattern;
  final void Function(PatternDocument) onEditPattern;
  final void Function(PatternDocument) onDeletePattern;
  final void Function(PatternDocument) onTapPattern;
  final VoidCallback onEditDesign;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<PatternDocument>>(
        stream: patternRepo.watchByDesign(design.id, userId: userId),
        builder: (context, patternSnap) {
          final patterns = patternSnap.data ?? [];

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              return CustomScrollView(
                slivers: [
                  _buildAppBar(context),
                  SliverToBoxAdapter(child: _buildInfoCard()),
                  SliverToBoxAdapter(
                    child: _buildPatternsHeader(isMobile, patterns.length),
                  ),
                  if (patternSnap.connectionState == ConnectionState.waiting)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(Sizes.xl),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (patterns.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyPatterns())
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? Sizes.md : Sizes.lg,
                        0,
                        isMobile ? Sizes.md : Sizes.lg,
                        Sizes.xxl,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 300,
                              mainAxisExtent: 180,
                              crossAxisSpacing: Sizes.md,
                              mainAxisSpacing: Sizes.md,
                            ),
                        delegate: SliverChildBuilderDelegate((_, i) {
                          final p = patterns[i];
                          return PatternCard(
                            pattern: p,
                            onTap: () => onTapPattern(p),
                            onEdit: () => onEditPattern(p),
                            onDelete: () => onDeletePattern(p),
                          );
                        }, childCount: patterns.length),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.verdeOliva,
      foregroundColor: Colors.white,
      pinned: true,
      expandedHeight: 110,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
        title: Text(
          design.name,
          style: const TextStyle(
            fontFamily: 'Lora',
            fontWeight: FontWeight.bold,
            fontSize: Sizes.fontSizeLg,
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Editar diseño',
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEditDesign,
        ),
        const SizedBox(width: Sizes.sm),
      ],
    );
  }

  Widget _buildInfoCard() {
    if (design.description.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sizes.lg, Sizes.md, Sizes.lg, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Sizes.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Sizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          design.description,
          style: const TextStyle(
            fontSize: Sizes.fontSizeMd,
            color: AppColors.texto,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPatternsHeader(bool isMobile, int count) {
    final button = ElevatedButton.icon(
      onPressed: onAddPattern,
      icon: const Icon(Icons.add, size: 18),
      label: const Text(
        'Nuevo patrón',
        style: TextStyle(
          fontSize: Sizes.fontSizeSm,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.resaltado,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, Sizes.buttonHeightSm),
        padding: const EdgeInsets.symmetric(horizontal: Sizes.md),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? Sizes.md : Sizes.lg,
        Sizes.md,
        isMobile ? Sizes.md : Sizes.lg,
        Sizes.sm,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patrones ($count)',
                  style: const TextStyle(
                    fontSize: Sizes.fontSizeXl,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textoFuerte,
                    fontFamily: 'Lora',
                  ),
                ),
                const SizedBox(height: Sizes.sm),
                Align(alignment: Alignment.centerLeft, child: button),
              ],
            )
          : Row(
              children: [
                Text(
                  'Patrones ($count)',
                  style: const TextStyle(
                    fontSize: Sizes.fontSizeXl,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textoFuerte,
                    fontFamily: 'Lora',
                  ),
                ),
                const Spacer(),
                button,
              ],
            ),
    );
  }

  Widget _buildEmptyPatterns() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Sizes.xxl,
        horizontal: Sizes.lg,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.grid_off_outlined, size: 56, color: AppColors.border),
            SizedBox(height: Sizes.md),
            Text(
              'Este diseño no tiene patrones todavía',
              style: TextStyle(
                fontSize: Sizes.fontSizeXl,
                fontWeight: FontWeight.bold,
                color: AppColors.textoFuerte,
              ),
            ),
            SizedBox(height: Sizes.sm),
            Text(
              'Agrega el primer patrón con el botón "Nuevo patrón".',
              style: TextStyle(
                fontSize: Sizes.fontSizeMd,
                color: AppColors.texto,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
