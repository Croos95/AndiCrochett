// lib/features/patterns/utils/stitch_graph.dart
//
// Modelo intermedio entre el PatternModel (texto) y los renderers
// (StitchSymbolPainter 2D, mass-spring 3D futuro). Representa la TELA, no
// el texto: cada puntada física en la tela es UN nodo, con conectividad
// explícita hacia sus padre(s) y hermano anterior.
//
// El builder convierte PatternModel.rawText → StitchGraph:
//   - parsea el rawText con PatternParser
//   - expande bloques (`[2pb, 1aum]x6` → 6 repeticiones de 2pb+1aum)
//   - emite nodos físicos: aumento ⇒ 2 nodos compartiendo padre,
//     disminución ⇒ 1 nodo con 2 padres, etc.
//
// Inmutable: si el patrón cambia, se construye un grafo nuevo. La
// construcción es lineal en el número de puntadas (~500-2000 para un
// amigurumi mediano, milisegundos en cualquier dispositivo).

import 'package:flutter/foundation.dart' show immutable;

import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';
import 'package:andicrochett/features/patterns/utils/pattern_parser.dart';
import 'package:andicrochett/features/patterns/utils/stitch_registry.dart';

// =============================================================================
// StitchRole
// =============================================================================
//
// Categoría topológica del nodo. NO altera matemática ni layout, pero
// permite que el renderer 2D dibuje símbolos diferentes (V para hijas
// de aumento, Λ para disminuciones) y que la UI resalte casos especiales
// ("muéstrame dónde están todos los aumentos").
//
// Importante: el `type` del nodo es siempre el código resuelto a un punto
// físico (`pb`, `pa`...). Los operadores como `aum` o `dis` NO aparecen
// como `type` — el builder los resuelve a `pb` y deja la semántica en
// `role`.

enum StitchRole {
  /// Puntada estándar: 1 padre, 1 hija, sin caso especial.
  normal,

  /// Una de las 2+ hijas producidas por un aumento. Las hermanas comparten
  /// exactamente el mismo `parentIds` (lista de 1 elemento).
  increaseChild,

  /// Hija producida por una disminución. `parentIds.length == 2`.
  decreaseChild,

  /// Cadena de la fila de fundación (patrones de filas que arrancan con
  /// una hilera de cadenas, sin vuelta anterior). `parentIds` está vacío.
  foundationChain,

  /// Puntada de la V1 nacida del anillo mágico. `parentIds` está vacío
  /// — conceptualmente "cuelga" del centro del anillo.
  magicRingMember,

  /// Cadena de subida al inicio de una vuelta. NO consume puntos de la
  /// vuelta anterior; sirve solo para alcanzar la altura del siguiente
  /// punto. `parentIds` está vacío.
  liftingChain,

  /// Cadena en medio de una vuelta. SÍ es estructural — patrones tipo
  /// "Cad en medio" forman espacios decorativos (granny squares, calados).
  /// `parentIds` está vacío (las cadenas no se "tejen sobre" otro punto).
  structuralChain,
}

// =============================================================================
// StitchNode
// =============================================================================

/// Una puntada física individual en la tela.
///
/// Cada `aum` del patrón genera 2 nodos con el mismo `parentIds`. Cada `dis`
/// genera 1 nodo con `parentIds.length == 2`. Ver `StitchGraphBuilder` para
/// la lógica completa.
@immutable
class StitchNode {
  /// Identificador único global dentro del grafo. Asignado de forma
  /// monotónica por el builder. No significa nada por sí solo — solo
  /// permite referenciar nodos sin tener que pasar referencias.
  final int id;

  /// Número de vuelta (1-indexed, para coincidir con el texto del patrón
  /// "V1", "R1"). 0 queda reservado para una futura fila de fundación
  /// explícita; el builder actual asigna foundationChain al `round` de
  /// la primera vuelta que aparezca.
  final int round;

  /// Posición dentro de su vuelta (0-indexed). Define el orden visual:
  /// indexInRound=0 es donde empezamos a tejer la vuelta.
  final int indexInRound;

  /// Código del punto resuelto a tipo físico: `pb`, `pa`, `cad`...
  /// NUNCA `aum` o `dis` (esos son operaciones, no tipos físicos).
  /// Para saber si fue un aumento, inspecciona `role`.
  final String type;

  /// Categoría topológica. Ver `StitchRole`.
  final StitchRole role;

  /// IDs de los nodos de la vuelta anterior que sostienen a este.
  /// - 0 elementos: fundación, magic ring, cadena (cualquier rol "Chain").
  /// - 1 elemento: caso normal o hija de aumento.
  /// - 2 elementos: hija de disminución.
  /// Lista inmutable para evitar mutaciones accidentales del simulador.
  final List<int> parentIds;

  /// ID del nodo anterior en la MISMA vuelta. null si es el primero.
  /// El "siguiente hermano" NO se guarda aquí: se deriva en
  /// `StitchGraph.nextSiblingOf` para mantener StitchNode inmutable y
  /// evitar problemas circulares al construir.
  final int? prevSiblingId;

  /// Índice de la línea (0-indexed) en el rawText del PatternModel de
  /// donde vino este nodo. Permite que al tocar un nodo en el render,
  /// la UI pueda resaltar la línea correspondiente del texto.
  final int sourceRowIndex;

  /// Índice del elemento dentro de `ParsedRow.elements` que generó este
  /// nodo. Combinado con `sourceRowIndex` apunta al token exacto del patrón.
  final int sourceElementIndex;

  const StitchNode({
    required this.id,
    required this.round,
    required this.indexInRound,
    required this.type,
    required this.role,
    required this.parentIds,
    required this.prevSiblingId,
    required this.sourceRowIndex,
    required this.sourceElementIndex,
  });

  /// Acceso conveniente a la definición del registry. Si el `type` es
  /// desconocido retorna la definición vacía (0/0) — no lanza. Casi
  /// siempre conocido porque el builder filtra antes de emitir.
  StitchDefinition get definition => StitchRegistry.forCode(type);
}

// =============================================================================
// StitchRound
// =============================================================================

/// Metadatos por vuelta. Se computa una vez al construir el grafo;
/// permite al renderer consultar info de la vuelta sin recorrer nodos.
@immutable
class StitchRound {
  /// Número de vuelta (1-indexed).
  final int number;

  /// ID del primer nodo de la vuelta (indexInRound == 0).
  final int startNodeId;

  /// ID del último nodo (indexInRound == nodeCount - 1).
  final int endNodeId;

  /// Total de puntadas en la vuelta. Es el `total` que aparece en el texto
  /// del patrón ("V2: 6aum (12)" → 12).
  final int nodeCount;

  /// True si la vuelta cierra sobre sí misma (patrón circular/mixed).
  /// El simulador 3D agregará un resorte extra entre `endNodeId` y
  /// `startNodeId` para preservar la topología de aro.
  final bool isClosed;

  const StitchRound({
    required this.number,
    required this.startNodeId,
    required this.endNodeId,
    required this.nodeCount,
    required this.isClosed,
  });
}

// =============================================================================
// StitchGraph
// =============================================================================

/// Representación estructural completa de un patrón, lista para visualizar.
@immutable
class StitchGraph {
  /// Todos los nodos en orden de emisión (por vuelta, dentro de vuelta por
  /// índice). Lista inmutable.
  final List<StitchNode> nodes;

  /// Metadatos por vuelta, ordenados por número de vuelta.
  final List<StitchRound> rounds;

  /// Tipo del patrón. Determina si el layout 2D usa anillos concéntricos
  /// (circular), grid lineal (rows), o ambos (mixed).
  final PatternType type;

  /// Cantidad de puntadas que nacen del anillo mágico, o 0 si no aplica.
  /// Usado por el layout circular para saber cuántos puntos rodean el
  /// "radio cero" del primer anillo.
  final int magicRingSize;

  /// Errores capturados durante la construcción (códigos desconocidos,
  /// faltan padres, etc.). El grafo se construye igual; los errores son
  /// informativos y la UI puede mostrarlos como advertencias.
  final List<PatternError> buildErrors;

  /// Índice id → nodo para lookup O(1). Privado: los consumidores usan
  /// `nodeById`.
  final Map<int, StitchNode> _byId;

  const StitchGraph._({
    required this.nodes,
    required this.rounds,
    required this.type,
    required this.magicRingSize,
    required this.buildErrors,
    required Map<int, StitchNode> byId,
  }) : _byId = byId;

  /// Constructor público — calcula el mapa de lookup automáticamente.
  factory StitchGraph({
    required List<StitchNode> nodes,
    required List<StitchRound> rounds,
    required PatternType type,
    required int magicRingSize,
    List<PatternError> buildErrors = const [],
  }) {
    final byId = <int, StitchNode>{};
    for (final n in nodes) {
      byId[n.id] = n;
    }
    return StitchGraph._(
      nodes: List.unmodifiable(nodes),
      rounds: List.unmodifiable(rounds),
      type: type,
      magicRingSize: magicRingSize,
      buildErrors: List.unmodifiable(buildErrors),
      byId: byId,
    );
  }

  /// Lookup O(1) por id. Retorna null si el id no existe.
  StitchNode? nodeById(int id) => _byId[id];

  /// Lista de nodos de una vuelta, ordenados por indexInRound. O(n) en el
  /// peor caso — aceptable para grafos pequeños. Si se vuelve hot se puede
  /// cachear por número de vuelta.
  List<StitchNode> nodesInRound(int roundNumber) {
    return nodes.where((n) => n.round == roundNumber).toList()
      ..sort((a, b) => a.indexInRound.compareTo(b.indexInRound));
  }

  /// Siguiente nodo hermano en la misma vuelta. null si es el último.
  ///
  /// IMPORTANTE: para vueltas circulares (`isClosed=true`), retorna null al
  /// llegar al final — la conectividad anular se modela en
  /// `StitchRound.isClosed`, NO como un nextSibling implícito. Esto evita
  /// ambigüedades en el simulador y permite a los renderers decidir cómo
  /// dibujar la unión.
  StitchNode? nextSiblingOf(StitchNode node) {
    // Buscamos un nodo de la misma vuelta cuyo prevSiblingId sea el nuestro.
    for (final candidate in nodes) {
      if (candidate.round == node.round && candidate.prevSiblingId == node.id) {
        return candidate;
      }
    }
    return null;
  }

  /// Resuelve la lista de IDs de padres a sus nodos reales.
  List<StitchNode> parentsOf(StitchNode node) {
    final result = <StitchNode>[];
    for (final pid in node.parentIds) {
      final p = _byId[pid];
      if (p != null) result.add(p);
    }
    return result;
  }
}

// =============================================================================
// StitchGraphBuilder
// =============================================================================
//
// Algoritmo de alto nivel:
//
//   parse rawText → List<ParsedLine>
//   for each parsed row:
//     resetear cursor de padres a 0 (apunta a _prevRound[0])
//     for each element:
//       expandir bloques (multiplicar in-place)
//       for each stitch:
//         consumir `consumed` padres del cursor
//         emitir `produced` nodos hijos
//   construir lista de StitchRound a partir de los nodos emitidos
//
// El cursor de padres es la pieza no trivial. Para preservar la
// conectividad real del crochet, el orden en que consumimos padres
// importa: si V1 tiene 6 puntos y V2 dice "6aum", el primer aum consume
// el padre 0 (sus 2 hijas apuntan a él), el segundo aum consume el padre
// 1, y así sucesivamente.

class StitchGraphBuilder {
  final PatternModel _pattern;

  // ── Estado mutable durante la construcción ──────────────────────────────
  final List<StitchNode> _nodes = [];
  final List<StitchRound> _rounds = [];
  final List<PatternError> _errors = [];

  /// Próximo id a asignar. Monotónico, nunca decrece.
  int _nextId = 0;

  /// Nodos de la vuelta anterior, en orden. Lo que el cursor recorre.
  List<StitchNode> _prevRound = const [];

  /// Nodos de la vuelta actual mientras se construye.
  List<StitchNode> _currentRound = [];

  /// Posición en `_prevRound` desde la cual consumir el próximo padre.
  int _parentCursor = 0;

  /// Tamaño total del anillo mágico detectado en esta construcción.
  int _magicRingSize = 0;

  /// True si en esta vuelta apareció un marcador `AM`. Hace que las
  /// puntadas siguientes de V1 se etiqueten como magicRingMember.
  /// Se resetea al inicio de cada vuelta.
  bool _pendingMagicRingTag = false;

  /// True mientras se expanden los stitches de un BlockElement. Permite
  /// distinguir cadenas en medio de un bloque (structural) de cadenas
  /// sueltas (lifting o structural según posición).
  bool _inBlock = false;

  /// Metadatos de la fuente de la línea/elemento que se está procesando.
  /// Se propagan a cada StitchNode emitido para back-tracking visual.
  int _currentSourceRowIndex = 0;
  int _currentSourceElementIndex = 0;
  int _currentRoundNumber = 0;

  StitchGraphBuilder._(this._pattern);

  /// Punto de entrada. Crea un grafo a partir de un PatternModel.
  static StitchGraph fromPattern(PatternModel pattern) {
    final builder = StitchGraphBuilder._(pattern);
    return builder._build();
  }

  StitchGraph _build() {
    // 1. Parseo del rawText. Notas (#nota:) y líneas vacías se filtran
    //    dentro de parseAll. Cada vuelta válida viene con su índice de
    //    línea original, que propagaremos a los nodos.
    final (parsedLines, parseErrors) = PatternParser.parseAll(_pattern.rawText);
    _errors.addAll(parseErrors);

    // 2. Procesamiento vuelta a vuelta. El orden importa: cada vuelta
    //    necesita la vuelta anterior ya emitida para consumir padres.
    for (final parsed in parsedLines) {
      _currentSourceRowIndex = parsed.sourceLineIndex;
      _processRow(parsed.row);
    }

    return StitchGraph(
      nodes: _nodes,
      rounds: _rounds,
      type: _pattern.type,
      magicRingSize: _magicRingSize,
      buildErrors: _errors,
    );
  }

  void _processRow(ParsedRow row) {
    // Reset de estado por-vuelta. El cursor de padres siempre arranca en 0
    // (la primera puntada de la vuelta consume el primer padre disponible).
    _currentRoundNumber = row.number;
    _currentRound = [];
    _parentCursor = 0;
    _pendingMagicRingTag = false;
    _inBlock = false;

    for (int i = 0; i < row.elements.length; i++) {
      _currentSourceElementIndex = i;
      _processElement(row.elements[i]);
    }

    // Vuelta vacía (todos los elementos fueron AM o códigos desconocidos):
    // no la registramos para no contaminar la lista de rounds.
    if (_currentRound.isEmpty) return;

    // Las vueltas circulares cierran sobre sí mismas. En `mixed` asumimos
    // circular por defecto; un futuro V2 podría leer una directiva por
    // vuelta para refinar esto (algunos amigurumis hacen V1-V3 circular
    // y luego abren a filas para apéndices).
    final isCircular =
        _pattern.type == PatternType.circular ||
        _pattern.type == PatternType.mixed;
    _rounds.add(
      StitchRound(
        number: row.number,
        startNodeId: _currentRound.first.id,
        endNodeId: _currentRound.last.id,
        nodeCount: _currentRound.length,
        isClosed: isCircular,
      ),
    );

    // La vuelta actual pasa a ser la previa para la próxima iteración.
    _prevRound = List.unmodifiable(_currentRound);
  }

  void _processElement(PatternElement element) {
    if (element is StitchElement) {
      _processStitch(element);
    } else if (element is BlockElement) {
      // Expandimos el bloque: ejecutar las stitches en orden, multiplier veces.
      // Marcamos `_inBlock` para que las cadenas internas se clasifiquen como
      // structuralChain (la regla del editor: "dentro de bloques, cad siempre
      // es estructural"). Restauramos el flag al salir para no contaminar.
      final wasInBlock = _inBlock;
      _inBlock = true;
      for (int rep = 0; rep < element.multiplier; rep++) {
        for (final s in element.stitches) {
          _processStitch(s);
        }
      }
      _inBlock = wasInBlock;
    }
  }

  void _processStitch(StitchElement stitch) {
    final code = stitch.type;

    // ── Caso especial: marcador AM ────────────────────────────────────────
    // No emite nodos. Solo activa el flag que etiqueta las puntadas
    // siguientes de V1 como magicRingMember. Si aparece fuera de V1 lo
    // reportamos pero ignoramos (no rompemos el grafo).
    if (code == 'AM') {
      if (_currentRoundNumber == 1) {
        _pendingMagicRingTag = true;
      } else {
        _errors.add(
          PatternError(
            'AM solo es válido en V1 (encontrado en V$_currentRoundNumber)',
            rowIndex: _currentRoundNumber,
          ),
        );
      }
      return;
    }

    // Códigos desconocidos: reportamos pero seguimos. Queremos que el
    // grafo se construya lo más completo posible — un punto desconocido
    // no debe convertir el patrón en una bola de "no se pudo renderizar".
    if (!StitchRegistry.isKnown(code)) {
      _errors.add(
        PatternError(
          'Código de punto desconocido: "$code"',
          rowIndex: _currentRoundNumber,
        ),
      );
      return;
    }

    final def = StitchRegistry.forCode(code);

    // Una "stitch de cantidad N" se procesa como N stitches independientes.
    // Cada uno consume sus propios padres del cursor. Esto es lo que hace
    // que "3pb" consuma 3 padres distintos en lugar de 3 desde el mismo.
    for (int rep = 0; rep < stitch.quantity; rep++) {
      _emitOneStitch(code, def);
    }
  }

  /// Emite los nodos hijos correspondientes a UN punto (no repetido).
  ///
  /// - Aumento: 1 padre consumido → 2 hijas emitidas (compartiendo padre).
  /// - Aumento triple: 1 padre → 3 hijas.
  /// - Disminución: 2 padres consumidos → 1 hija (con 2 padres).
  /// - Normal: 1 padre → 1 hija.
  /// - Cadena: 0 padres → 1 hija sin padre.
  void _emitOneStitch(String code, StitchDefinition def) {
    final role = _roleFor(code);
    final parents = _consumeParents(code, def);

    // Validación matemática suave: si pidió consumir más padres de los que
    // quedaban, reportamos pero seguimos con lo que pudimos. El render se
    // verá raro pero no rompe.
    if (parents.length < def.consumed && _prevRound.isNotEmpty) {
      _errors.add(
        PatternError(
          'V$_currentRoundNumber: faltan padres para "$code" '
          '(necesita ${def.consumed}, disponibles ${parents.length})',
          rowIndex: _currentRoundNumber,
        ),
      );
    }

    if (def.produced == 0) {
      // Marcadores u operaciones sin producción. Nada que emitir.
      return;
    }

    // El "tipo físico" del nodo siempre es un punto real, nunca una
    // operación. `_resolvePhysicalType` convierte aum/dis/aumtri en `pb`
    // (asunción de patrones de amigurumi típicos: las hijas de un aumento
    // son del mismo tipo que el resto de la vuelta, que casi siempre es pb).
    // El símbolo V/Λ lo decide el painter a partir del `role`.
    final physicalType = _resolvePhysicalType(code);

    for (int childIdx = 0; childIdx < def.produced; childIdx++) {
      final node = StitchNode(
        id: _nextId++,
        round: _currentRoundNumber,
        indexInRound: _currentRound.length,
        type: physicalType,
        role: role,
        parentIds: List.unmodifiable(parents),
        prevSiblingId: _currentRound.isEmpty ? null : _currentRound.last.id,
        sourceRowIndex: _currentSourceRowIndex,
        sourceElementIndex: _currentSourceElementIndex,
      );
      _currentRound.add(node);
      _nodes.add(node);

      if (role == StitchRole.magicRingMember) {
        _magicRingSize++;
      }
    }
  }

  /// Decide el rol del nodo según código + contexto.
  StitchRole _roleFor(String code) {
    // Magic ring tiene prioridad sobre el código. Si estamos en V1 después
    // de un AM, cualquier puntada se considera miembro del anillo, aunque
    // su código sea `pb` o `aum`.
    if (_pendingMagicRingTag && _currentRoundNumber == 1) {
      return StitchRole.magicRingMember;
    }

    switch (code) {
      case 'aum':
      case 'inc':
      case 'aumtri':
        return StitchRole.increaseChild;

      case 'dis':
      case 'dec':
      case 'dism':
        return StitchRole.decreaseChild;

      case 'cad':
      case 'ch':
        // Sin vuelta anterior → fila de fundación. Dentro de un bloque,
        // la regla del editor es "siempre estructural". Si es el primer
        // elemento de la vuelta y hay vuelta anterior, es cadena de subida.
        if (_prevRound.isEmpty) return StitchRole.foundationChain;
        if (_inBlock) return StitchRole.structuralChain;
        return _currentRound.isEmpty
            ? StitchRole.liftingChain
            : StitchRole.structuralChain;

      default:
        return StitchRole.normal;
    }
  }

  /// Convierte códigos operacionales (aum/dis) en su tipo físico.
  /// Para todo lo demás retorna el código tal cual.
  ///
  /// Asunción simplificadora: aumentos y disminuciones son siempre de pb.
  /// Si en el futuro queremos "aumento de pa", habrá que extender
  /// `StitchElement` con un campo `producedType` opcional.
  String _resolvePhysicalType(String code) {
    switch (code) {
      case 'aum':
      case 'inc':
      case 'aumtri':
      case 'dis':
      case 'dec':
      case 'dism':
        return 'pb';
      default:
        return code;
    }
  }

  /// Consume `def.consumed` padres del cursor y los retorna como lista
  /// de IDs. Casos especiales que retornan lista vacía:
  /// - Sin vuelta anterior (V1 sin AM, o fila de fundación): nada que consumir.
  /// - Magic ring: las puntadas cuelgan del centro virtual, no de un nodo.
  /// - Cadenas: nunca tienen padre estructural en sentido tejido.
  ///
  /// Avanza el cursor de padres una posición por cada padre consumido.
  List<int> _consumeParents(String code, StitchDefinition def) {
    if (_prevRound.isEmpty) return const [];
    if (_pendingMagicRingTag && _currentRoundNumber == 1) return const [];
    if (code == 'cad' || code == 'ch') return const [];

    final result = <int>[];
    for (int i = 0; i < def.consumed; i++) {
      if (_parentCursor >= _prevRound.length) break;
      result.add(_prevRound[_parentCursor].id);
      _parentCursor++;
    }
    return result;
  }
}
