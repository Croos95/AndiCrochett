import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/core/widgets/empty_state_view.dart';
import 'package:andicrochett/features/designs/data/models/design_model.dart';
import 'package:andicrochett/features/designs/data/repositories/design_repository.dart';
import 'package:andicrochett/features/designs/presentation/pages/design_detail_page.dart';
import 'package:andicrochett/features/designs/presentation/pages/design_editor_page.dart';
import 'package:andicrochett/features/designs/presentation/widgets/design_card.dart';
import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';
import 'package:andicrochett/features/patterns/data/repositories/pattern_repository.dart';

// =============================================================================
//  DesignsPage
//  Punto de entrada del dashboard: muestra los diseños del usuario en una cuadrícula.
//  Al tocar una tarjeta se abre DesignDetailPage con la lista de patrones del diseño.
// =============================================================================

class DesignsPage extends StatefulWidget {
  const DesignsPage({super.key});

  @override
  State<DesignsPage> createState() => _DesignsPageState();
}

class _DesignsPageState extends State<DesignsPage> {
  final _designRepo = DesignRepository();
  final _patternRepo = PatternRepository();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _designRepo.dispose();
    super.dispose();
  }

  void _openDetail(DesignModel design) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DesignDetailPage(designId: design.id!)),
    );
  }

  void _openEditor({DesignModel? existing}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DesignEditorPage(existing: existing)),
    );
  }

  Future<void> _confirmDelete(DesignModel design) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
        ),
        title: const Text('Eliminar diseño'),
        content: Text(
          '¿Eliminar "${design.name}"?\n'
          'Sus patrones también serán eliminados. Esta acción es irreversible.',
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
      await _patternRepo.deleteByDesign(design.id!);
      await _designRepo.delete(design.id!);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Diseño eliminado')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final stream = userId != null
        ? _designRepo.watchByUser(userId)
        : Stream.value(const <DesignModel>[]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Container(
          color: AppColors.background,
          child: Column(
            children: [
              _buildHeader(isMobile),
              Expanded(
                child: StreamBuilder<List<DesignModel>>(
                  stream: stream,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.verdeOliva,
                        ),
                      );
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snap.error}',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      );
                    }
                    final all = snap.data ?? [];
                    final q = _searchQuery.toLowerCase();
                    final filtered = q.isEmpty
                        ? all
                        : all
                              .where(
                                (d) =>
                                    d.name.toLowerCase().contains(q) ||
                                    d.description.toLowerCase().contains(q),
                              )
                              .toList();

                    if (filtered.isEmpty) {
                      return const EmptyStateView(
                        icon: Icons.design_services_outlined,
                        title: 'Aún no hay diseños',
                        subtitle:
                            'Crea tu primer diseño con el botón "Nuevo diseño".',
                      );
                    }

                    return StreamBuilder<List<PatternModel>>(
                      stream: _patternRepo.watchByUser(userId ?? ''),
                      builder: (_, patSnap) {
                        final allPatterns = patSnap.data ?? [];
                        final counts = <int, int>{};
                        for (final p in allPatterns) {
                          counts[p.designId] = (counts[p.designId] ?? 0) + 1;
                        }
                        return _DesignGrid(
                          designs: filtered,
                          isMobile: isMobile,
                          patternCounts: counts,
                          onTap: _openDetail,
                          onEdit: (d) => _openEditor(existing: d),
                          onDelete: _confirmDelete,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    final button = ElevatedButton.icon(
      onPressed: () => _openEditor(),
      icon: const Icon(Icons.add, size: 18),
      label: const Text(
        'Nuevo diseño',
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

    final search = TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(
        hintText: 'Buscar diseños...',
        hintStyle: const TextStyle(
          fontSize: Sizes.fontSizeSm,
          color: AppColors.texto,
        ),
        prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.texto),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.lino),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.lino),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.verdeOliva),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sizes.md,
          vertical: Sizes.sm,
        ),
        isDense: true,
      ),
      style: const TextStyle(fontSize: Sizes.fontSizeSm),
    );

    const title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Mis Diseños',
          style: TextStyle(
            fontSize: Sizes.fontSizeXxl,
            fontWeight: FontWeight.bold,
            color: AppColors.textoFuerte,
            fontFamily: 'Lora',
          ),
        ),
        Text(
          'Tu colección de patrones de crochet \u{1FAA1}',
          style: TextStyle(fontSize: Sizes.fontSizeSm, color: AppColors.texto),
        ),
      ],
    );

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(Sizes.md),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(bottom: BorderSide(color: AppColors.lino)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const SizedBox(height: Sizes.sm),
            search,
            const SizedBox(height: Sizes.sm),
            Align(alignment: Alignment.centerLeft, child: button),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.lg,
        vertical: Sizes.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.lino)),
      ),
      child: Row(
        children: [
          title,
          const SizedBox(width: Sizes.lg),
          SizedBox(width: 280, child: search),
          const Spacer(),
          button,
        ],
      ),
    );
  }
}

// ── Cuadrícula ───────────────────────────────────────────────────────────────

class _DesignGrid extends StatelessWidget {
  const _DesignGrid({
    required this.designs,
    required this.isMobile,
    required this.patternCounts,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final List<DesignModel> designs;
  final bool isMobile;

  /// Conteo de patrones por design ID, calculado desde un único stream.
  final Map<int, int> patternCounts;
  final void Function(DesignModel) onTap;
  final void Function(DesignModel) onEdit;
  final void Function(DesignModel) onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? Sizes.md : Sizes.lg),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 320,
          mainAxisExtent: 190,
          crossAxisSpacing: Sizes.md,
          mainAxisSpacing: Sizes.md,
        ),
        itemCount: designs.length,
        itemBuilder: (_, i) {
          final d = designs[i];
          return DesignCard(
            design: d,
            patternCount: patternCounts[d.id ?? 0] ?? 0,
            onTap: () => onTap(d),
            onEdit: () => onEdit(d),
            onDelete: () => onDelete(d),
          );
        },
      ),
    );
  }
}
