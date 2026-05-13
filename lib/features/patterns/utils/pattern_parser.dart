// lib/features/patterns/utils/pattern_parser.dart
//
// Parser: rawText → AST (lista de ParsedRow). El AST NO expande los bloques;
// `[2pb, 1aum]x6` queda como UN BlockElement con 2 StitchElements y mult=6.
// La expansión a nodos físicos individuales ocurre más tarde en
// StitchGraphBuilder (ver stitch_graph.dart).
//
// Esta separación importa porque:
//   - el editor muestra el AST en chips compactos (no quiere ver 12 puntos
//     individuales cuando escribió `[2pb]x6`);
//   - el motor de visualización sí necesita los nodos expandidos;
//   - el validador matemático puede operar sobre cualquiera de los dos.

import 'package:andicrochett/features/patterns/utils/stitch_registry.dart';

// =============================================================================
// AST del patrón
// =============================================================================

/// Nodo base del AST. `StitchElement` y `BlockElement` son los únicos
/// concretos; el editor existente ya hace `is StitchElement` / `is BlockElement`
/// en pattern_editor_page.dart, así que esta jerarquía es contrato público.
abstract class PatternElement {}

/// Un punto simple (posiblemente repetido), ej: `pb`, `3pb`, `aum`, `AM`.
class StitchElement extends PatternElement {
  /// Código tal como aparece en el texto (`pb`, `aum`, `AM`, …).
  /// No se valida aquí — el builder decide si es conocido. Mantener el
  /// parser tolerante permite formatos personalizados sin tocar este archivo.
  final String type;

  /// Repeticiones del punto. Mínimo 1: un código solo sin número
  /// (ej. `pb`) equivale a quantity=1.
  final int quantity;

  StitchElement(this.type, this.quantity);

  @override
  String toString() => quantity == 1 ? type : '$quantity$type';
}

/// Un bloque repetible: `[<stitches>] x N`.
///
/// Solo soporta UN nivel de anidamiento (sin bloques dentro de bloques).
/// El parser rechaza `[[a]x2]x3` con error explícito. Coincide con lo que
/// el editor puede generar y simplifica el modelo del builder.
class BlockElement extends PatternElement {
  /// Contenido literal del bloque, sin expandir.
  final List<StitchElement> stitches;

  /// Repeticiones del bloque completo. Siempre >= 1.
  final int multiplier;

  BlockElement(this.stitches, this.multiplier);

  @override
  String toString() {
    final inner = stitches.map((s) => s.toString()).join(', ');
    return '[$inner]x$multiplier';
  }
}

/// Una vuelta parseada.
class ParsedRow {
  /// Número de vuelta (1-indexed). 0 indica fallo legacy del stub anterior;
  /// el parser real ya no produce 0 sin errores.
  final int number;

  /// Elementos en el orden en que aparecen.
  final List<PatternElement> elements;

  ParsedRow(this.number, this.elements);
}

/// Tupla (vuelta parseada, índice de línea en el rawText original).
/// El índice permite que cada nodo del grafo recuerde DE QUÉ LÍNEA del
/// texto vino, para resaltar al usuario qué línea editar cuando toca un
/// punto en el render.
typedef ParsedLine = ({ParsedRow row, int sourceLineIndex});

// =============================================================================
// PatternParseException
// =============================================================================

/// Excepción de sintaxis del parser. El editor existente la captura con
/// try/catch (ver _parseRawText en pattern_editor_page.dart); el validador
/// la convierte a PatternError con rowIndex apropiado.
class PatternParseException implements Exception {
  /// Mensaje en español, listo para mostrar al usuario.
  final String message;

  /// Posición aproximada en la línea (0-indexed) o -1 si no aplica.
  final int column;

  PatternParseException(this.message, {this.column = -1});

  @override
  String toString() => column < 0 ? message : '$message (col $column)';
}

// =============================================================================
// PatternParser
// =============================================================================
//
// Gramática soportada (EBNF informal):
//
//   line     := marker INT ':' WS+ elements WS* total? WS*
//   marker   := 'R' | 'V' | 'r' | 'v'    (row / vuelta — ambos válidos)
//   elements := element (WS* ',' WS* element)*
//   element  := stitch | block
//   stitch   := INT? CODE                (ej. 'pb', '3pb', 'AM')
//   block    := '[' WS* elements WS* ']' WS* ('x' | 'X') WS* INT
//   total    := '(' WS* INT WS* ')'      (informativo; se parsea y descarta)
//   CODE     := letra (letra)*           (mayúsculas y minúsculas)
//
// Tolerancias intencionadas: espacios opcionales alrededor de comas,
// corchetes y 'x'; 'x' y 'X' intercambiables.
//
// El sufijo `(total)` no se valida contra la suma real — eso pertenece al
// validador (que es parte de Phase 0.5, no de la 0).

class PatternParser {
  // Clase estrictamente estática.
  PatternParser._();

  /// Parsea UNA línea (sin saltos de línea). El llamador debe filtrar las
  /// líneas vacías y de notas (`#nota: ...`) antes de invocar.
  ///
  /// Lanza `PatternParseException` si la sintaxis falla.
  static ParsedRow parseRow(String line) {
    final cursor = _Cursor(line);
    cursor.skipWs();

    // ── 1. Marcador "R<num>:" o "V<num>:" ────────────────────────────────
    if (cursor.eof) {
      throw PatternParseException('Línea vacía');
    }
    final marker = cursor.current;
    if (marker != 'R' && marker != 'V' && marker != 'r' && marker != 'v') {
      throw PatternParseException(
        'La línea debe empezar con R o V (recibido "$marker")',
        column: cursor.position,
      );
    }
    cursor.advance();

    final rowNumber = cursor.readInt();
    if (rowNumber == null) {
      throw PatternParseException(
        'Falta número de vuelta después de "$marker"',
        column: cursor.position,
      );
    }
    cursor.skipWs();
    if (!cursor.consume(':')) {
      throw PatternParseException(
        'Falta ":" después de "$marker$rowNumber"',
        column: cursor.position,
      );
    }

    // ── 2. Lista de elementos ─────────────────────────────────────────────
    final elements = _parseElements(cursor, isInsideBlock: false);

    // ── 3. Sufijo opcional "(total)" ──────────────────────────────────────
    // Sintácticamente lo exigimos bien escrito; semánticamente no lo
    // cruzamos contra la suma real (responsabilidad del validador).
    cursor.skipWs();
    if (!cursor.eof && cursor.current == '(') {
      cursor.advance();
      cursor.skipWs();
      final total = cursor.readInt();
      if (total == null) {
        throw PatternParseException(
          'Sufijo "(...)" debe contener un número',
          column: cursor.position,
        );
      }
      cursor.skipWs();
      if (!cursor.consume(')')) {
        throw PatternParseException(
          'Falta ")" al cerrar el sufijo de total',
          column: cursor.position,
        );
      }
    }

    return ParsedRow(rowNumber, elements);
  }

  /// Parsea el rawText completo. Devuelve las vueltas válidas + los errores
  /// recolectados. Cada vuelta válida viene con el índice de su línea
  /// original (post-trim) en el rawText para back-tracking visual.
  ///
  /// Líneas vacías y las que empiezan con `#` (notas/comentarios) se omiten
  /// silenciosamente. Líneas que fallan al parsear se añaden a la lista de
  /// errores pero no detienen el proceso.
  static (List<ParsedLine>, List<PatternError>) parseAll(String rawText) {
    final lines = rawText.split('\n');
    final rows = <ParsedLine>[];
    final errors = <PatternError>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      try {
        final row = parseRow(line);
        rows.add((row: row, sourceLineIndex: i));
      } on PatternParseException catch (e) {
        // rowIndex=-1 porque la línea no parseó: no podemos asignarle un
        // número de vuelta confiable. El editor puede mapearlo al índice
        // de línea si necesita.
        errors.add(PatternError(e.message, rowIndex: -1));
      }
    }

    return (rows, errors);
  }

  // ── Parsing interno ────────────────────────────────────────────────────

  /// Parsea una lista de elementos separados por coma.
  ///
  /// `isInsideBlock` cambia el manejo de cierres:
  /// - false: encontrar un "]" suelto sería un error (no hay bloque abierto).
  /// - true: encontrar "]" termina la lista limpiamente (el bloque cierra).
  static List<PatternElement> _parseElements(
    _Cursor cursor, {
    required bool isInsideBlock,
  }) {
    final result = <PatternElement>[];

    while (true) {
      cursor.skipWs();

      // Condiciones de salida limpia
      if (cursor.eof) break;
      if (cursor.current == '(') {
        break; // empieza el sufijo (total) — para llamadas top-level
      }
      if (cursor.current == ']') {
        break; // cierre de bloque (válido solo si isInsideBlock)
      }

      // Si ya hay un elemento, exigimos coma antes del siguiente.
      if (result.isNotEmpty) {
        if (!cursor.consume(',')) break;
        cursor.skipWs();
      }

      final el = _parseElement(cursor, isInsideBlock: isInsideBlock);
      if (el == null) {
        // Después de una coma esperamos algo. Si no hay nada, error.
        throw PatternParseException(
          'Se esperaba un punto o bloque después de ","',
          column: cursor.position,
        );
      }
      result.add(el);
    }

    return result;
  }

  /// Parsea UN elemento: stitch o block.
  /// Retorna null si no encuentra nada parseable.
  static PatternElement? _parseElement(
    _Cursor cursor, {
    required bool isInsideBlock,
  }) {
    cursor.skipWs();
    if (cursor.eof) return null;

    // ── Caso bloque: "[ ... ] x N" ────────────────────────────────────────
    if (cursor.current == '[') {
      // Bloques anidados no se soportan — el editor no los puede generar
      // y soportarlos complicaría el modelo del builder sin ganancia clara.
      if (isInsideBlock) {
        throw PatternParseException(
          'No se permiten bloques anidados',
          column: cursor.position,
        );
      }
      cursor.advance();
      final inner = _parseElements(cursor, isInsideBlock: true);
      cursor.skipWs();
      if (!cursor.consume(']')) {
        throw PatternParseException(
          'Falta "]" para cerrar el bloque',
          column: cursor.position,
        );
      }
      cursor.skipWs();
      if (!cursor.consume('x') && !cursor.consume('X')) {
        throw PatternParseException(
          'Falta "x" después de "]" — los bloques siempre se multiplican',
          column: cursor.position,
        );
      }
      cursor.skipWs();
      final mult = cursor.readInt();
      if (mult == null || mult < 1) {
        throw PatternParseException(
          'El multiplicador del bloque debe ser un entero >= 1',
          column: cursor.position,
        );
      }
      // `inner` solo puede contener StitchElement porque ya bloqueamos
      // anidamiento arriba. El cast es seguro.
      final stitches = inner.cast<StitchElement>().toList();
      return BlockElement(stitches, mult);
    }

    // ── Caso stitch: "QTY? CODE" ──────────────────────────────────────────
    // Quantity es opcional; ausencia ⇒ 1.
    final qtyStartPos = cursor.position;
    final qty = cursor.readInt() ?? 1;
    final readQty = cursor.position > qtyStartPos;
    final code = cursor.readIdentifier();
    if (code == null) {
      // Si había qty pero no code, el usuario olvidó el código. Error claro.
      if (readQty) {
        throw PatternParseException(
          'Falta código de punto después del número',
          column: cursor.position,
        );
      }
      return null;
    }
    if (qty < 1) {
      throw PatternParseException(
        'La cantidad de un punto debe ser >= 1',
        column: cursor.position,
      );
    }
    return StitchElement(code, qty);
  }
}

// =============================================================================
// _Cursor — lector de caracteres con posición
// =============================================================================
//
// Una abstracción mínima para no manipular `pos` directamente en cada
// función. No es un tokenizer completo: los tokens (números, identificadores)
// se reconocen bajo demanda.

class _Cursor {
  final String _src;
  int _pos = 0;

  _Cursor(this._src);

  /// Posición actual (0-indexed). Útil para mensajes de error.
  int get position => _pos;

  /// True si ya se consumió toda la línea.
  bool get eof => _pos >= _src.length;

  /// Carácter actual sin consumir. NO llamar si `eof` es true.
  String get current => _src[_pos];

  /// Consume un carácter sin importar cuál.
  void advance() => _pos++;

  /// Consume el carácter `c` si coincide con el actual. Retorna true si se
  /// consumió, false si no (cursor no se mueve en ese caso).
  bool consume(String c) {
    if (eof || current != c) return false;
    _pos++;
    return true;
  }

  /// Avanza sobre espacios y tabulaciones (NO sobre saltos de línea — el
  /// parser opera línea por línea).
  void skipWs() {
    while (!eof && (current == ' ' || current == '\t')) {
      _pos++;
    }
  }

  /// Lee un entero ASCII si lo encuentra. Retorna null si el carácter
  /// actual no es dígito. NO salta espacios — el llamador decide.
  int? readInt() {
    if (eof || !_isDigit(current)) return null;
    final start = _pos;
    while (!eof && _isDigit(current)) {
      _pos++;
    }
    return int.parse(_src.substring(start, _pos));
  }

  /// Lee un identificador (secuencia de letras ASCII). Retorna null si el
  /// carácter actual no es letra. NO salta espacios.
  String? readIdentifier() {
    if (eof || !_isAlpha(current)) return null;
    final start = _pos;
    while (!eof && _isAlpha(current)) {
      _pos++;
    }
    return _src.substring(start, _pos);
  }

  static bool _isDigit(String c) {
    final code = c.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39; // '0'..'9'
  }

  static bool _isAlpha(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 0x41 && code <= 0x5A) || // A..Z
        (code >= 0x61 && code <= 0x7A); //     a..z
  }
}
