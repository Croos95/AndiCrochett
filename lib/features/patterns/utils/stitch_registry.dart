// lib/features/patterns/utils/stitch_registry.dart
//
// Catálogo global de puntos de crochet soportados por la app.
// Combina tres dimensiones por punto:
//   1. Matemática (consumed/produced) — usada por el editor para validar
//      que el patrón cuadra vuelta a vuelta.
//   2. Símbolo (StitchSymbol) — usada por el painter 2D para elegir el glifo.
//   3. Geometría (StitchGeometry) — usada por el simulador 3D como longitud
//      reposo de los resortes y, en 2D, para espaciar vueltas proporcionalmente.

import 'package:flutter/foundation.dart' show immutable;

// =============================================================================
// StitchSymbol
// =============================================================================
//
// Cada glifo sigue la convención estándar de los diagramas de crochet
// (ISO/asiáticos) que aparecen en revistas y libros. El painter sabrá
// dibujar cada uno; aquí solo enumeramos. `none` es un placeholder defensivo
// para códigos desconocidos: el painter puede pintar un "?" o nada.

/// Glifo visual estándar para un punto en un diagrama 2D de crochet.
enum StitchSymbol {
  none, // sin símbolo — placeholder para códigos desconocidos
  oval, // ◯ cadena (ch / cad)
  dot, // ● punto deslizado / raso (slst / pr / pd)
  cross, // × punto bajo (sc / pb)
  tSlash, // T con barra inclinada — medio punto alto (hdc / pma)
  tStem1, // T con un tallo — punto alto (dc / pa)
  tStem2, // T con dos barras — punto alto doble (tr / pad / dpa)
  tStem3, // T con tres barras — triple punto alto (tpa)
  vMerge, // V — aumento (2+ hijas convergen en un padre)
  caret, // Λ — disminución (1 hija con 2 padres)
  ring, // ◯ — marcador central del anillo mágico (AM)
  bubble, // ⌬ punto burbuja (pbub)
  backLoop, // ⌐ vuelta por hebra trasera (vcad)
  frontLoop, // ¬ vuelta por hebra delantera (vcadf)
}

// =============================================================================
// StitchGeometry
// =============================================================================
//
// Proporciones físicas relativas, todas adimensionales. La unidad base 1.0
// equivale al ancho/alto de un punto bajo (pb). Estas constantes son las que
// el simulador masa-resorte usará como longitud-reposo de los resortes entre
// nodos vecinos: si un pa tiene restHeight=2.0, su resorte con el padre será
// el doble de largo que el de un pb. En 2D ayudan a que vueltas con puntos
// altos se vean visualmente más altas que vueltas con pb.

/// Proporciones físicas relativas de un tipo de punto.
@immutable
class StitchGeometry {
  /// Ancho horizontal reposo. Casi todos los puntos son 1.0 — solo cambian
  /// si el punto ocupa más espacio horizontal (ninguno en el catálogo actual,
  /// pero queda como punto de extensión).
  final double restWidth;

  /// Altura vertical reposo. Define cuánto crece la tela por vuelta.
  /// Valores típicos: pb=1.0, pma=1.5, pa=2.0, pad=3.0, tpa=4.0.
  final double restHeight;

  /// Profundidad reposo (cuánto sobresale del plano de la tela). Solo se usa
  /// en 3D. El pa tiene más profundidad que el pb porque su bucle es más alto.
  final double restDepth;

  const StitchGeometry({
    this.restWidth = 1.0,
    this.restHeight = 1.0,
    this.restDepth = 0.5,
  });
}

// =============================================================================
// StitchDefinition
// =============================================================================
//
// Cada entrada del registry. `consumed`/`produced` quedan POSICIONALES porque
// hay código existente que ya usa `const StitchDefinition(0, 0)` como
// fallback (ver pattern_editor_page.dart). Los campos visuales se agregan
// como NOMBRADOS con defaults para no romper esos call sites.

/// Define el comportamiento matemático y visual de un punto de crochet.
@immutable
class StitchDefinition {
  /// Puntos de la vuelta anterior que este punto consume.
  /// Ej.: aum consume 1, dis consume 2, cad consume 0.
  final int consumed;

  /// Puntos nuevos producidos para la vuelta siguiente.
  /// Ej.: pb produce 1, aum produce 2, aumtri produce 3.
  final int produced;

  /// Glifo a dibujar en diagrama 2D.
  final StitchSymbol symbol;

  /// Proporciones físicas para layout 2D/3D.
  final StitchGeometry geometry;

  const StitchDefinition(
    this.consumed,
    this.produced, {
    this.symbol = StitchSymbol.none,
    this.geometry = const StitchGeometry(),
  });
}

// =============================================================================
// StitchRegistry
// =============================================================================
//
// El catálogo cubre TODOS los códigos que la paleta del editor usa
// (`_kStitches` en pattern_editor_page.dart) más las abreviaciones inglesas
// estándar (sc, dc, ch, …) para que patrones importados de fuentes externas
// se parseen sin trabajo extra.
//
// Convenciones:
// - `AM` (anillo mágico) es un MARCADOR, no un punto: consumed=0, produced=0.
//   El StitchGraphBuilder lo detecta y etiqueta como magicRingMember a los
//   puntos siguientes de V1.
// - Geometría: `pb` es la unidad (1.0×1.0). Los puntos altos crecen en
//   `restHeight`; las cadenas casi no levantan (0.3); el punto deslizado
//   prácticamente no aporta altura (0.1).

class StitchRegistry {
  /// Mapa global de código → definición.
  ///
  /// Mayúsculas se reservan para marcadores (`AM`); puntos reales van en
  /// minúsculas. Aliases ES/EN apuntan a la misma matemática y símbolo.
  static const Map<String, StitchDefinition> stitches = {
    // ── Marcador ───────────────────────────────────────────────────────────
    // AM no es un punto. Su 0/0 evita que afecte la matemática del editor;
    // el builder lo intercepta para etiquetar la V1 como magic ring.
    'AM': StitchDefinition(
      0,
      0,
      symbol: StitchSymbol.ring,
      geometry: StitchGeometry(restWidth: 0.0, restHeight: 0.0, restDepth: 0.0),
    ),

    // ── Cadenas ────────────────────────────────────────────────────────────
    // Las cadenas levantan muy poco; en 3D casi no son columnas estructurales.
    'cad': StitchDefinition(
      0,
      1,
      symbol: StitchSymbol.oval,
      geometry: StitchGeometry(restHeight: 0.3, restDepth: 0.15),
    ),
    'ch': StitchDefinition(
      // alias inglés
      0,
      1,
      symbol: StitchSymbol.oval,
      geometry: StitchGeometry(restHeight: 0.3, restDepth: 0.15),
    ),

    // ── Punto bajo (referencia: altura 1.0) ────────────────────────────────
    'pb': StitchDefinition(1, 1, symbol: StitchSymbol.cross),
    'sc': StitchDefinition(1, 1, symbol: StitchSymbol.cross), // alias EN

    // ── Medio punto alto ───────────────────────────────────────────────────
    'pma': StitchDefinition(
      1,
      1,
      symbol: StitchSymbol.tSlash,
      geometry: StitchGeometry(restHeight: 1.5),
    ),
    'hdc': StitchDefinition(
      // alias EN
      1,
      1,
      symbol: StitchSymbol.tSlash,
      geometry: StitchGeometry(restHeight: 1.5),
    ),

    // ── Punto alto ─────────────────────────────────────────────────────────
    'pa': StitchDefinition(
      1,
      1,
      symbol: StitchSymbol.tStem1,
      geometry: StitchGeometry(restHeight: 2.0, restDepth: 0.6),
    ),
    'dc': StitchDefinition(
      // alias EN
      1,
      1,
      symbol: StitchSymbol.tStem1,
      geometry: StitchGeometry(restHeight: 2.0, restDepth: 0.6),
    ),

    // ── Punto alto doble ───────────────────────────────────────────────────
    'pad': StitchDefinition(
      1,
      1,
      symbol: StitchSymbol.tStem2,
      geometry: StitchGeometry(restHeight: 3.0, restDepth: 0.7),
    ),
    'dpa': StitchDefinition(
      // alias ES (doble punto alto)
      1,
      1,
      symbol: StitchSymbol.tStem2,
      geometry: StitchGeometry(restHeight: 3.0, restDepth: 0.7),
    ),
    'tr': StitchDefinition(
      // alias EN (treble crochet)
      1,
      1,
      symbol: StitchSymbol.tStem2,
      geometry: StitchGeometry(restHeight: 3.0, restDepth: 0.7),
    ),

    // ── Triple punto alto ──────────────────────────────────────────────────
    'tpa': StitchDefinition(
      1,
      1,
      symbol: StitchSymbol.tStem3,
      geometry: StitchGeometry(restHeight: 4.0, restDepth: 0.8),
    ),

    // ── Aumento (1 → 2) ────────────────────────────────────────────────────
    // El builder emite 2 nodos hermanos con role=increaseChild compartiendo
    // el mismo parentIds. La geometría del aum NO se usa directamente — el
    // builder resuelve el tipo físico a 'pb', así que la altura visual viene
    // de la geometría de pb.
    'aum': StitchDefinition(1, 2, symbol: StitchSymbol.vMerge),
    'inc': StitchDefinition(1, 2, symbol: StitchSymbol.vMerge), // alias EN

    // ── Aumento triple (1 → 3) ─────────────────────────────────────────────
    'aumtri': StitchDefinition(1, 3, symbol: StitchSymbol.vMerge),

    // ── Disminución (2 → 1) ────────────────────────────────────────────────
    // Dos padres "se fusionan" en una hija. El builder pone los 2 ids en
    // parentIds y emite UN nodo con role=decreaseChild.
    'dis': StitchDefinition(2, 1, symbol: StitchSymbol.caret),
    'dism': StitchDefinition(2, 1, symbol: StitchSymbol.caret), // alias ES alt
    'dec': StitchDefinition(2, 1, symbol: StitchSymbol.caret), // alias EN

    // ── Punto deslizado / raso ─────────────────────────────────────────────
    // Apenas levanta tela. En 3D el simulador casi lo trata como una unión
    // (restHeight muy bajo).
    'pr': StitchDefinition(
      1,
      1,
      symbol: StitchSymbol.dot,
      geometry: StitchGeometry(restHeight: 0.1, restDepth: 0.0),
    ),
    'pd': StitchDefinition(
      // alias ES (punto deslizado)
      1,
      1,
      symbol: StitchSymbol.dot,
      geometry: StitchGeometry(restHeight: 0.1, restDepth: 0.0),
    ),
    'slst': StitchDefinition(
      // alias EN
      1,
      1,
      symbol: StitchSymbol.dot,
      geometry: StitchGeometry(restHeight: 0.1, restDepth: 0.0),
    ),

    // ── Punto burbuja ──────────────────────────────────────────────────────
    // Produce volumen — el simulador 3D le da más profundidad que un pb.
    'pbub': StitchDefinition(
      1,
      1,
      symbol: StitchSymbol.bubble,
      geometry: StitchGeometry(restHeight: 1.5, restDepth: 1.2),
    ),

    // ── Vueltas por hebra (texturizado) ────────────────────────────────────
    // Topológicamente iguales a un pb. Solo el símbolo cambia para que el
    // lector reconozca el efecto visual deseado.
    'vcad': StitchDefinition(1, 1, symbol: StitchSymbol.backLoop),
    'vcadf': StitchDefinition(1, 1, symbol: StitchSymbol.frontLoop),
  };

  /// Acceso seguro al registry — retorna una definición vacía (0/0) si el
  /// código no existe, evitando un null check en cada call site. Útil cuando
  /// se sabe que el código vino de input del usuario y queremos degradar
  /// sin estallar.
  static StitchDefinition forCode(String code) {
    return stitches[code] ?? const StitchDefinition(0, 0);
  }

  /// True si el código corresponde a un punto reconocido. Llamarlo permite
  /// reportar un PatternError explícito en vez de degradar silenciosamente.
  static bool isKnown(String code) => stitches.containsKey(code);
}

// =============================================================================
// PatternError
// =============================================================================
//
// Vive aquí por motivos históricos — la clase ya existía en este archivo
// y muchas partes del código la importan vía stitch_registry.dart. Mover
// el archivo causaría una cascada de imports innecesaria.

/// Error lógico o de sintaxis en un patrón de crochet.
class PatternError {
  /// Mensaje legible para el usuario (en español).
  final String message;

  /// Número de vuelta donde ocurrió, o -1 si es un error global / de línea
  /// no numerada. El editor lo usa para resaltar la vuelta específica.
  final int rowIndex;

  const PatternError(this.message, {this.rowIndex = -1});

  @override
  String toString() => message;
}
