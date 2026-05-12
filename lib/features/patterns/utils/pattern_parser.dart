// lib/features/patterns/utils/pattern_parser.dart

abstract class PatternElement {}

/// Representa un punto simple, ej: "2pb"
class StitchElement extends PatternElement {
  final String type;
  final int quantity;
  StitchElement(this.type, this.quantity);
}

/// Representa un bloque repetitivo, ej: "[2pb, 1aum] x 6"
class BlockElement extends PatternElement {
  final List<StitchElement> stitches;
  final int multiplier;
  BlockElement(this.stitches, this.multiplier);
}

/// Representa una vuelta completa traducida
class ParsedRow {
  final int number;
  final List<PatternElement> elements;
  ParsedRow(this.number, this.elements);
}

/// El traductor de texto a objetos
class PatternParser {
  // TODO: implementar parseRow con lógica real. Formato esperado por el editor:
  //   "V1: AM, 6pb"  →  ParsedRow(1, [StitchElement('AM',1), StitchElement('pb',6)])
  //   "V2: [2pb, 1aum]x6"  →  ParsedRow(2, [BlockElement([...], 6)])
  // Hasta que esto esté implementado, PatternModel.validate() siempre retorna []
  // y el bloqueo pre-save por errores matemáticos en PatternEditorPage no se activa.
  static ParsedRow parseRow(String line) {
    return ParsedRow(0, []);
  }
}