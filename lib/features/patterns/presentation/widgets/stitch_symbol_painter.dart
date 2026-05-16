// lib/features/patterns/presentation/widgets/stitch_symbol_painter.dart
//
// CustomPainter que dibuja un StitchGraph como diagrama 2D de crochet.
// Cada nodo se posiciona usando StitchLayoutEngine y se dibuja con el glifo
// estándar correspondiente a su StitchSymbol (× para pb, T con barras para
// puntos altos, V para hijas de aumento, Λ para disminución, ○ para cadena…).
//
// El painter es puro: recibe el grafo y el layout, no consulta repositorios.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/features/patterns/utils/stitch_graph.dart';
import 'package:andicrochett/features/patterns/utils/stitch_layout.dart';
import 'package:andicrochett/features/patterns/utils/stitch_registry.dart';

class StitchSymbolPainter extends CustomPainter {
  StitchSymbolPainter({
    required this.graph,
    required this.layout,
    this.showRoundLabels = true,
    this.highlightedNodeId,
  });

  final StitchGraph graph;
  final StitchLayout layout;
  final bool showRoundLabels;

  /// Si está seteado, ese nodo se dibuja con un círculo de resalte detrás.
  /// Lo usa la UI cuando el usuario toca una línea del texto del patrón.
  final int? highlightedNodeId;

  // ── Configuración visual ─────────────────────────────────────────────────
  // Tamaños proporcionales a cellSize para que cambiar la escala global no
  // requiera tocar cada constante.
  double get _symbolSize => layout.cellSize * 0.85;
  double get _strokeWidth => math.max(1.4, layout.cellSize * 0.08);

  @override
  void paint(Canvas canvas, Size size) {
    if (graph.nodes.isEmpty) return;

    // ── Encajar el contenido en el viewport ────────────────────────────────
    // El layout devuelve coordenadas lógicas con su propio bounding box.
    // Calculamos la escala para que quepa entero y centramos.
    final lw = layout.width;
    final lh = layout.height;
    if (lw <= 0 || lh <= 0) return;
    final scale = math.min(size.width / lw, size.height / lh);
    final offsetX = (size.width - lw * scale) / 2 - layout.minX * scale;
    final offsetY = (size.height - lh * scale) / 2 - layout.minY * scale;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    // ── Conexiones primero (para que los símbolos queden encima) ───────────
    _drawConnections(canvas);

    // ── Símbolos de cada nodo ──────────────────────────────────────────────
    for (final node in graph.nodes) {
      final pos = layout.positions[node.id];
      if (pos == null) continue;
      _drawNode(canvas, node, pos);
    }

    // ── Etiquetas de vuelta ────────────────────────────────────────────────
    if (showRoundLabels) {
      _drawRoundLabels(canvas);
    }

    // ── Marcador del anillo mágico ─────────────────────────────────────────
    if (graph.magicRingSize > 0) {
      _drawMagicRing(canvas);
    }

    canvas.restore();
  }

  // ── Conexiones padre→hijo ────────────────────────────────────────────────
  //
  // Una línea fina une cada nodo con sus padres. Para aumentos (2 hijas con
  // mismo padre) y disminuciones (1 hija con 2 padres) las líneas convergen
  // visualmente en el padre/hija sin necesidad de tratamiento especial.

  void _drawConnections(Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = _strokeWidth * 0.6
      ..style = PaintingStyle.stroke;

    for (final node in graph.nodes) {
      final childPos = layout.positions[node.id];
      if (childPos == null) continue;
      for (final pid in node.parentIds) {
        final parentPos = layout.positions[pid];
        if (parentPos == null) continue;
        canvas.drawLine(
          Offset(parentPos.x, parentPos.y),
          Offset(childPos.x, childPos.y),
          paint,
        );
      }
    }
  }

  // ── Dibuja un nodo ──────────────────────────────────────────────────────

  void _drawNode(Canvas canvas, StitchNode node, StitchPosition pos) {
    final center = Offset(pos.x, pos.y);
    final color = _colorFor(node);

    // Highlight de fondo (si aplica)
    if (highlightedNodeId == node.id) {
      final highlightPaint = Paint()
        ..color = AppColors.resaltado.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, _symbolSize * 0.75, highlightPaint);
    }

    final symbol = node.definition.symbol;
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (symbol) {
      case StitchSymbol.cross:
        _drawCross(canvas, center, paint);
        break;
      case StitchSymbol.oval:
        _drawOval(canvas, center, paint);
        break;
      case StitchSymbol.dot:
        _drawDot(canvas, center, fillPaint);
        break;
      case StitchSymbol.tSlash:
        _drawTStem(canvas, center, paint, bars: 0, withSlash: true);
        break;
      case StitchSymbol.tStem1:
        _drawTStem(canvas, center, paint, bars: 1);
        break;
      case StitchSymbol.tStem2:
        _drawTStem(canvas, center, paint, bars: 2);
        break;
      case StitchSymbol.tStem3:
        _drawTStem(canvas, center, paint, bars: 3);
        break;
      case StitchSymbol.vMerge:
        _drawV(canvas, center, paint);
        break;
      case StitchSymbol.caret:
        _drawCaret(canvas, center, paint);
        break;
      case StitchSymbol.ring:
        // El AM no emite nodo, así que en la práctica no llegamos aquí;
        // se dibuja el anillo central aparte en _drawMagicRing.
        _drawOval(canvas, center, paint);
        break;
      case StitchSymbol.bubble:
        _drawBubble(canvas, center, paint);
        break;
      case StitchSymbol.backLoop:
        _drawCross(canvas, center, paint);
        _drawUnderscore(canvas, center, paint);
        break;
      case StitchSymbol.frontLoop:
        _drawCross(canvas, center, paint);
        _drawOverscore(canvas, center, paint);
        break;
      case StitchSymbol.none:
        // Código desconocido — dibujamos un "?" para alertar al usuario sin
        // romper la visualización.
        _drawUnknown(canvas, center, color);
        break;
    }
  }

  // ── Glifos individuales ─────────────────────────────────────────────────

  void _drawCross(Canvas canvas, Offset c, Paint p) {
    final h = _symbolSize / 2;
    canvas.drawLine(Offset(c.dx - h, c.dy - h), Offset(c.dx + h, c.dy + h), p);
    canvas.drawLine(Offset(c.dx + h, c.dy - h), Offset(c.dx - h, c.dy + h), p);
  }

  void _drawOval(Canvas canvas, Offset c, Paint p) {
    final rect = Rect.fromCenter(
      center: c,
      width: _symbolSize,
      height: _symbolSize * 0.7,
    );
    canvas.drawOval(rect, p);
  }

  void _drawDot(Canvas canvas, Offset c, Paint p) {
    canvas.drawCircle(c, _symbolSize * 0.18, p);
  }

  /// Punto alto: tallo vertical con N barras horizontales y una barra
  /// superior tipo "T". Si `withSlash` es true, añade una barra diagonal
  /// (símbolo del medio punto alto).
  void _drawTStem(
    Canvas canvas,
    Offset c,
    Paint p, {
    required int bars,
    bool withSlash = false,
  }) {
    final half = _symbolSize / 2;
    // Tallo
    canvas.drawLine(
      Offset(c.dx, c.dy - half),
      Offset(c.dx, c.dy + half),
      p,
    );
    // Barra superior (la T)
    canvas.drawLine(
      Offset(c.dx - half * 0.6, c.dy - half),
      Offset(c.dx + half * 0.6, c.dy - half),
      p,
    );
    // Barras horizontales (estilo "tr" / "tpa")
    for (int i = 0; i < bars; i++) {
      final dy = c.dy - half * 0.4 + i * (half * 0.35);
      canvas.drawLine(
        Offset(c.dx - half * 0.45, dy),
        Offset(c.dx + half * 0.45, dy),
        p,
      );
    }
    if (withSlash) {
      canvas.drawLine(
        Offset(c.dx - half * 0.5, c.dy + half * 0.2),
        Offset(c.dx + half * 0.5, c.dy - half * 0.2),
        p,
      );
    }
  }

  void _drawV(Canvas canvas, Offset c, Paint p) {
    final h = _symbolSize / 2;
    canvas.drawLine(
      Offset(c.dx - h, c.dy - h * 0.8),
      Offset(c.dx, c.dy + h * 0.6),
      p,
    );
    canvas.drawLine(
      Offset(c.dx + h, c.dy - h * 0.8),
      Offset(c.dx, c.dy + h * 0.6),
      p,
    );
  }

  void _drawCaret(Canvas canvas, Offset c, Paint p) {
    final h = _symbolSize / 2;
    canvas.drawLine(
      Offset(c.dx - h, c.dy + h * 0.6),
      Offset(c.dx, c.dy - h * 0.8),
      p,
    );
    canvas.drawLine(
      Offset(c.dx + h, c.dy + h * 0.6),
      Offset(c.dx, c.dy - h * 0.8),
      p,
    );
  }

  void _drawBubble(Canvas canvas, Offset c, Paint p) {
    canvas.drawCircle(c, _symbolSize * 0.45, p);
    // Pequeña línea vertical interior para sugerir relieve.
    canvas.drawLine(
      Offset(c.dx, c.dy - _symbolSize * 0.45),
      Offset(c.dx, c.dy + _symbolSize * 0.45),
      p,
    );
  }

  void _drawUnderscore(Canvas canvas, Offset c, Paint p) {
    final h = _symbolSize / 2;
    canvas.drawLine(
      Offset(c.dx - h, c.dy + h * 1.0),
      Offset(c.dx + h, c.dy + h * 1.0),
      p,
    );
  }

  void _drawOverscore(Canvas canvas, Offset c, Paint p) {
    final h = _symbolSize / 2;
    canvas.drawLine(
      Offset(c.dx - h, c.dy - h * 1.0),
      Offset(c.dx + h, c.dy - h * 1.0),
      p,
    );
  }

  void _drawUnknown(Canvas canvas, Offset c, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          color: color,
          fontSize: _symbolSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(c.dx - tp.width / 2, c.dy - tp.height / 2),
    );
  }

  // ── Etiquetas de vuelta ─────────────────────────────────────────────────

  void _drawRoundLabels(Canvas canvas) {
    for (final round in graph.rounds) {
      // Etiquetamos en el primer nodo de la vuelta, ligeramente desplazado
      // hacia "fuera" (más lejos del centro en circular, más a la izquierda
      // en rows).
      final firstPos = layout.positions[round.startNodeId];
      if (firstPos == null) continue;
      final isCircular = round.isClosed;
      final Offset labelPos;
      if (isCircular) {
        // En circular, sacar la etiqueta radialmente hacia afuera.
        final dist = math.sqrt(
          firstPos.x * firstPos.x + firstPos.y * firstPos.y,
        );
        if (dist < 0.0001) {
          labelPos = Offset(firstPos.x, firstPos.y - layout.cellSize);
        } else {
          final factor = (dist + layout.cellSize * 0.8) / dist;
          labelPos = Offset(firstPos.x * factor, firstPos.y * factor);
        }
      } else {
        labelPos = Offset(firstPos.x - layout.cellSize * 1.2, firstPos.y);
      }

      final tp = TextPainter(
        text: TextSpan(
          text: 'V${round.number}',
          style: TextStyle(
            color: AppColors.textoFuerte,
            fontSize: layout.cellSize * 0.45,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(labelPos.dx - tp.width / 2, labelPos.dy - tp.height / 2),
      );
    }
  }

  // ── Anillo mágico ───────────────────────────────────────────────────────

  void _drawMagicRing(Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.bronce
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset.zero, layout.cellSize * 0.25, paint);
  }

  // ── Color por rol ───────────────────────────────────────────────────────
  //
  // Resaltar visualmente puntos especiales ayuda al lector a localizar
  // aumentos/disminuciones de un vistazo.

  Color _colorFor(StitchNode node) {
    switch (node.role) {
      case StitchRole.increaseChild:
        return AppColors.resaltado;
      case StitchRole.decreaseChild:
        return AppColors.error;
      case StitchRole.foundationChain:
      case StitchRole.liftingChain:
      case StitchRole.structuralChain:
        return AppColors.bronce;
      case StitchRole.magicRingMember:
        return AppColors.verdeOliva;
      case StitchRole.normal:
        return AppColors.textoFuerte;
    }
  }

  @override
  bool shouldRepaint(covariant StitchSymbolPainter old) {
    return old.graph != graph ||
        old.layout != layout ||
        old.showRoundLabels != showRoundLabels ||
        old.highlightedNodeId != highlightedNodeId;
  }
}
