// lib/features/patterns/presentation/pages/pattern_2d_viewer_page.dart
//
// Página que muestra un PatternModel como diagrama 2D de crochet. Usa el
// StitchGraphBuilder para resolver el rawText a un grafo de nodos físicos,
// StitchLayoutEngine para asignarles posición, y StitchSymbolPainter para
// dibujarlos como símbolos estándar (×, T, V, Λ, ○).
//
// La interacción se delega a InteractiveViewer (pinch-zoom y pan).

import 'package:flutter/material.dart';

import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';
import 'package:andicrochett/features/patterns/presentation/widgets/stitch_symbol_painter.dart';
import 'package:andicrochett/features/patterns/utils/stitch_graph.dart';
import 'package:andicrochett/features/patterns/utils/stitch_layout.dart';

class Pattern2DViewerPage extends StatefulWidget {
  const Pattern2DViewerPage({super.key, required this.pattern});

  final PatternModel pattern;

  @override
  State<Pattern2DViewerPage> createState() => _Pattern2DViewerPageState();
}

class _Pattern2DViewerPageState extends State<Pattern2DViewerPage> {
  // Toggle del usuario para mostrar las líneas que unen puntadas consecutivas
  // de la misma vuelta. Útil cuando las vueltas no se leen como anillos
  // (p.ej. porque el conteo cambia entre vueltas y los hijos no quedan
  // alineados radialmente con sus padres).
  bool _showSiblingLinks = false;

  @override
  Widget build(BuildContext context) {
    // El grafo y el layout se calculan una sola vez por construcción de la
    // página. Para un patrón típico (~500 nodos) tarda milisegundos.
    final graph = StitchGraphBuilder.fromPattern(widget.pattern);
    final layout = StitchLayoutEngine.compute(graph);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.verdeOliva,
        foregroundColor: Colors.white,
        title: Text(
          widget.pattern.name,
          style: const TextStyle(
            fontFamily: 'Lora',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _showSiblingLinks
                ? 'Ocultar líneas entre puntadas de la vuelta'
                : 'Mostrar líneas entre puntadas de la vuelta',
            icon: Icon(
              _showSiblingLinks
                  ? Icons.timeline
                  : Icons.show_chart_outlined,
            ),
            onPressed: () =>
                setState(() => _showSiblingLinks = !_showSiblingLinks),
          ),
        ],
      ),
      body: Column(
        children: [
          if (graph.buildErrors.isNotEmpty) _ErrorsBanner(errors: graph.buildErrors),
          Expanded(
            child: graph.nodes.isEmpty
                ? const _EmptyDiagram()
                : _DiagramCanvas(
                    graph: graph,
                    layout: layout,
                    showSiblingLinks: _showSiblingLinks,
                  ),
          ),
          const _Legend(),
        ],
      ),
    );
  }
}

// ── Canvas con zoom/pan ───────────────────────────────────────────────────

class _DiagramCanvas extends StatelessWidget {
  const _DiagramCanvas({
    required this.graph,
    required this.layout,
    required this.showSiblingLinks,
  });
  final StitchGraph graph;
  final StitchLayout layout;
  final bool showSiblingLinks;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      // Permitir zoom amplio para diagramas con muchas vueltas.
      minScale: 0.3,
      maxScale: 6.0,
      boundaryMargin: const EdgeInsets.all(200),
      child: SizedBox.expand(
        child: CustomPaint(
          painter: StitchSymbolPainter(
            graph: graph,
            layout: layout,
            showSiblingLinks: showSiblingLinks,
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────

class _EmptyDiagram extends StatelessWidget {
  const _EmptyDiagram();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(Sizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_off, size: Sizes.iconXl, color: AppColors.border),
            SizedBox(height: Sizes.sm),
            Text(
              'Este patrón aún no tiene puntadas para visualizar.\n'
              'Edita el texto del patrón con vueltas tipo "V1: 6pb (6)".',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textoFuerte),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Errores del builder ───────────────────────────────────────────────────

class _ErrorsBanner extends StatelessWidget {
  const _ErrorsBanner({required this.errors});
  final List<dynamic> errors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warning.withValues(alpha: 0.25),
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.md,
        vertical: Sizes.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, size: Sizes.iconSm, color: AppColors.warning),
          const SizedBox(width: Sizes.sm),
          Expanded(
            child: Text(
              '${errors.length} aviso(s) al construir el diagrama. '
              'El render puede verse incompleto.',
              style: const TextStyle(
                color: AppColors.textoFuerte,
                fontSize: Sizes.fontSizeSm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Leyenda ──────────────────────────────────────────────────────────────
//
// Pequeña tira en la parte inferior que muestra el código de colores. Ayuda
// a leer el diagrama sin tener que memorizar las convenciones.

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.md,
        vertical: Sizes.sm,
      ),
      child: Wrap(
        spacing: Sizes.md,
        runSpacing: Sizes.xs,
        children: const [
          _LegendItem(color: AppColors.textoFuerte, label: 'Normal'),
          _LegendItem(color: AppColors.resaltado, label: 'Aumento'),
          _LegendItem(color: AppColors.error, label: 'Disminución'),
          _LegendItem(color: AppColors.bronce, label: 'Cadena'),
          _LegendItem(color: AppColors.verdeOliva, label: 'Anillo mágico'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: Sizes.xs),
        Text(
          label,
          style: const TextStyle(
            fontSize: Sizes.fontSizeSm,
            color: AppColors.textoFuerte,
          ),
        ),
      ],
    );
  }
}
