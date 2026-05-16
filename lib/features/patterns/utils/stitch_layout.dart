// lib/features/patterns/utils/stitch_layout.dart
//
// Asigna una posición (x, y) a cada StitchNode del grafo para renderizado 2D.
// La estrategia depende de PatternType:
//   - circular/mixed: anillos concéntricos. La vuelta r vive en radio
//     r * radialStep; los nodos se distribuyen uniformemente por ángulo.
//   - rows: cuadrícula. La vuelta r ocupa la fila y = r * rowHeight; los
//     nodos se ordenan de izquierda a derecha por indexInRound.
//
// El layout es puro: no toca Canvas. El painter consume el resultado.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;

import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';
import 'package:andicrochett/features/patterns/utils/stitch_graph.dart';

/// Posición 2D de un nodo, en coordenadas lógicas (sin escala de pantalla).
/// El painter aplica la escala y centra el contenido en el viewport.
@immutable
class StitchPosition {
  final double x;
  final double y;
  const StitchPosition(this.x, this.y);
}

/// Resultado del cálculo de layout.
@immutable
class StitchLayout {
  /// Mapa id-de-nodo → posición lógica.
  final Map<int, StitchPosition> positions;

  /// Bounding box del contenido, útil para que el painter ajuste el zoom
  /// inicial al tamaño del viewport.
  final double minX, minY, maxX, maxY;

  /// Separación nominal entre nodos vecinos en X (el "1.0" de la geometría).
  /// El painter lo usa como referencia para el tamaño del símbolo.
  final double cellSize;

  const StitchLayout({
    required this.positions,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
    required this.cellSize,
  });

  double get width => maxX - minX;
  double get height => maxY - minY;
}

class StitchLayoutEngine {
  StitchLayoutEngine._();

  /// Punto de entrada. Decide el algoritmo a partir del tipo del patrón.
  static StitchLayout compute(StitchGraph graph) {
    if (graph.nodes.isEmpty) {
      return const StitchLayout(
        positions: {},
        minX: 0,
        minY: 0,
        maxX: 0,
        maxY: 0,
        cellSize: 1.0,
      );
    }
    switch (graph.type) {
      case PatternType.circular:
      case PatternType.mixed:
        return _layoutCircular(graph);
      case PatternType.rows:
        return _layoutRows(graph);
    }
  }

  // ── Circular: anillos concéntricos ──────────────────────────────────────
  //
  // Vuelta 1 va en un radio pequeño (cerca del centro pero no en 0, para que
  // el anillo mágico se distinga). Las vueltas siguientes se alejan en pasos
  // de `radialStep`. Los nodos se ubican por ángulo según su indexInRound /
  // total de la vuelta, partiendo de las 12 en punto y avanzando horario.

  static StitchLayout _layoutCircular(StitchGraph graph) {
    const double cellSize = 28.0;
    const double radialStep = 36.0; // distancia entre anillos
    const double innerRadius = 18.0; // radio de la V1

    final positions = <int, StitchPosition>{};
    double minX = 0, minY = 0, maxX = 0, maxY = 0;

    for (final round in graph.rounds) {
      final radius = innerRadius + (round.number - 1) * radialStep;
      final count = round.nodeCount;
      if (count == 0) continue;
      final nodesInRound = graph.nodesInRound(round.number);
      for (int i = 0; i < nodesInRound.length; i++) {
        // -pi/2 alinea el primer nodo con las "12 en punto"; el sentido
        // horario coincide con cómo se teje un amigurumi visto desde abajo.
        final angle = -math.pi / 2 + (2 * math.pi * i) / count;
        final x = radius * math.cos(angle);
        final y = radius * math.sin(angle);
        positions[nodesInRound[i].id] = StitchPosition(x, y);
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }

    // Padding alrededor para que los símbolos no se peguen al borde.
    const pad = 24.0;
    return StitchLayout(
      positions: positions,
      minX: minX - pad,
      minY: minY - pad,
      maxX: maxX + pad,
      maxY: maxY + pad,
      cellSize: cellSize,
    );
  }

  // ── Rows: cuadrícula horizontal ─────────────────────────────────────────
  //
  // Cada vuelta es una fila; la altura entre filas usa la `restHeight`
  // del primer nodo de la fila (por si la fila es de pa o pad).

  static StitchLayout _layoutRows(StitchGraph graph) {
    const double cellSize = 28.0;
    const double colStep = 32.0;
    const double rowStepBase = 36.0;

    final positions = <int, StitchPosition>{};
    double minX = 0, minY = 0, maxX = 0, maxY = 0;

    // Las vueltas suelen ir de abajo hacia arriba en patrones tejidos.
    // Para evitar invertir mentalmente, dibujamos V1 abajo (y grande) y
    // crecemos hacia arriba (y disminuye con cada vuelta).
    double currentY = 0;
    for (final round in graph.rounds) {
      final nodesInRound = graph.nodesInRound(round.number);
      if (nodesInRound.isEmpty) continue;

      // Altura visual de esta fila: tomar la mayor restHeight de los nodos.
      double rowHeight = 1.0;
      for (final n in nodesInRound) {
        final h = n.definition.geometry.restHeight;
        if (h > rowHeight) rowHeight = h;
      }

      for (int i = 0; i < nodesInRound.length; i++) {
        final x = i * colStep;
        final y = currentY;
        positions[nodesInRound[i].id] = StitchPosition(x, y);
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
      // Subir para la siguiente vuelta (y disminuye = sube en pantalla).
      currentY -= rowStepBase * rowHeight / 1.0;
    }

    const pad = 24.0;
    return StitchLayout(
      positions: positions,
      minX: minX - pad,
      minY: minY - pad,
      maxX: maxX + pad,
      maxY: maxY + pad,
      cellSize: cellSize,
    );
  }
}
