import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';
import 'package:andicrochett/features/patterns/data/repositories/pattern_repository.dart';
import 'package:andicrochett/features/patterns/presentation/pages/pattern_editor_page.dart';

// =============================================================================
//  PatternDetailPage
//  Vista de solo lectura de un PatternDocument.
//  – Muestra el texto de instrucción de cada vuelta con un badge de número.
//  – Muestra los errores de validación del PatternEngine en la parte superior.
//  – El botón de edición en el AppBar abre PatternEditorPage(existing: doc).
//  – Muestra una tarjeta de texto crudo cuando el patrón no puede parsearse.
// =============================================================================

class PatternDetailPage extends StatefulWidget {
  const PatternDetailPage({super.key, required this.patternId});

  final String patternId;

  @override
  State<PatternDetailPage> createState() => _PatternDetailPageState();
}

class _PatternDetailPageState extends State<PatternDetailPage> {
  // El repositorio se guarda como campo para no reinstanciarlo en cada
  // reconstrucción del widget (StatelessWidget crearía una nueva instancia cada vez).
  final _repo = PatternRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<PatternDocument?>(
        stream: _repo.watchById(widget.patternId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final doc = snapshot.data;
          if (doc == null) {
            return const Center(child: Text('Patrón no encontrado'));
          }
          return _PatternDetailContent(doc: doc);
        },
      ),
    );
  }
}

// ── Content widget ─────────────────────────────────────────────────────────

class _PatternDetailContent extends StatelessWidget {
  const _PatternDetailContent({required this.doc});
  final PatternDocument doc;

  @override
  Widget build(BuildContext context) {
    // tryParse() y validate() usan cachés late final en PatternDocument,
    // por lo que llamar a ambos aquí cuesta un parseo por emisión del stream, no dos.
    final pattern = doc.tryParse();
    final errors = doc.validate();
    final allLines = doc.rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    // Separar líneas de vueltas de líneas de notas para la visualización
    final rawLines = allLines.where((l) => !l.startsWith('#')).toList();
    // Construye el mapa número-de-vuelta → nota
    final notes = <int, String>{};
    for (int i = 0; i < allLines.length; i++) {
      if (allLines[i].startsWith('#nota:') && i > 0) {
        // Find the preceding row line
        final note = allLines[i].substring(6).trim();
        // Asocia la nota a la vuelta que precede a esta línea
        for (int j = i - 1; j >= 0; j--) {
          if (!allLines[j].startsWith('#')) {
            try {
              final nr = PatternParser.parseRow(allLines[j]).number;
              notes[nr] = note;
            } catch (_) {}
            break;
          }
        }
      }
    }

    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        if (errors.isNotEmpty)
          SliverToBoxAdapter(child: _ErrorBanner(errors: errors)),
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
                  label: doc.type.label,
                  color: doc.type.color,
                ),
                _MetaChip(
                  icon: Icons.bar_chart,
                  label: doc.difficulty.label,
                  color: doc.difficulty.color,
                ),
                _MetaChip(
                  icon: doc.status.icon,
                  label: doc.status.label,
                  color: doc.status.color,
                ),
                _MetaChip(
                  icon: Icons.format_list_numbered,
                  label: '${doc.rowCount} filas',
                  color: AppColors.bronce,
                ),
                if (doc.suggestedMaterial.isNotEmpty)
                  _MetaChip(
                    icon: Icons.texture,
                    label: doc.suggestedMaterial,
                    color: AppColors.verdeOliva,
                  ),
                if (doc.hookSize.isNotEmpty)
                  _MetaChip(
                    icon: Icons.straighten,
                    label: 'Gancho ${doc.hookSize}',
                    color: AppColors.bronce,
                  ),
                if (pattern != null)
                  const _MetaChip(
                    icon: Icons.check_circle_outline,
                    label: 'Parseado correctamente',
                    color: AppColors.success,
                  ),
              ],
            ),
          ),
        ),
        if (pattern != null) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Sizes.lg),
              child: Text(
                'Filas',
                style: TextStyle(
                  fontSize: Sizes.fontSizeXl,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textoFuerte,
                  fontFamily: 'Lora',
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Sizes.lg,
              Sizes.sm,
              Sizes.lg,
              Sizes.xxl,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final row = pattern.rows[index];
                final rawLine = index < rawLines.length ? rawLines[index] : '';
                final hasError = errors.any((e) => e.row == row.number);
                return _RowCard(
                  row: row,
                  rawLine: rawLine,
                  hasError: hasError,
                  note: notes[row.number],
                );
              }, childCount: pattern.rows.length),
            ),
          ),
        ] else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Sizes.lg),
              child: Container(
                padding: const EdgeInsets.all(Sizes.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(Sizes.radiusLg),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'El patrón no pudo ser parseado correctamente. '
                  'Abre el editor para revisar las instrucciones.',
                  style: TextStyle(
                    fontSize: Sizes.fontSizeSm,
                    color: AppColors.error,
                  ),
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
              child: _RawTextCard(rawText: doc.rawText),
            ),
          ),
        ],
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
          doc.name,
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
                  PatternEditorPage(designId: doc.designId, existing: doc),
            ),
          ),
        ),
        const SizedBox(width: Sizes.sm),
      ],
    );
  }
}

// ── Row card ────────────────────────────────────────────────────────────────

class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.row,
    required this.rawLine,
    required this.hasError,
    this.note,
  });

  final RowPattern row;
  final String rawLine;
  final bool hasError;
  final String? note;

  @override
  Widget build(BuildContext context) {
    // Strip "R1: " prefix — el número ya aparece en el badge
    final displayLine = rawLine.replaceFirst(RegExp(r'^R\d+:\s*'), '');
    return Container(
      margin: const EdgeInsets.only(bottom: Sizes.sm),
      decoration: BoxDecoration(
        color: hasError
            ? AppColors.error.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(Sizes.radiusMd),
        border: Border.all(
          color: hasError
              ? AppColors.error.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Sizes.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: hasError ? AppColors.error : AppColors.verdeOliva,
                borderRadius: BorderRadius.circular(Sizes.radiusSm),
              ),
              alignment: Alignment.center,
              child: Text(
                'R${row.number}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: Sizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: Sizes.fontSizeLg,
                      color: AppColors.texto,
                    ),
                  ),
                  if (note != null && note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '📝 $note',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.bronce,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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

// ── Error banner ────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.errors});
  final List<PatternError> errors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(Sizes.lg, Sizes.md, Sizes.lg, 0),
      padding: const EdgeInsets.all(Sizes.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Sizes.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 16),
              const SizedBox(width: Sizes.xs),
              Text(
                '${errors.length} error${errors.length > 1 ? "es" : ""} de validación',
                style: const TextStyle(
                  fontSize: Sizes.fontSizeSm,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: Sizes.xs),
          ...errors.map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '• R${e.row}: ${e.message}',
                style: const TextStyle(
                  fontSize: Sizes.fontSizeSm,
                  color: AppColors.error,
                ),
              ),
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
