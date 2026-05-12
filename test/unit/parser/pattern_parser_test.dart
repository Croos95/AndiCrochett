// test/unit/parser/pattern_parser_test.dart
//
// Cubre el parser de patrones de crochet: happy path, bloques con multiplicador,
// total opcional `(N)`, y los errores explícitos que el editor mostrará.
// Es la pieza con más reglas del proyecto, así que merece pruebas densas.

import 'package:andicrochett/features/patterns/utils/pattern_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PatternParser.parseRow — casos válidos', () {
    test('vuelta simple con un solo punto', () {
      final row = PatternParser.parseRow('R1: 6pb');
      expect(row.number, 1);
      expect(row.elements, hasLength(1));
      final s = row.elements.first as StitchElement;
      expect(s.type, 'pb');
      expect(s.quantity, 6);
    });

    test('quantity omitida equivale a 1', () {
      final row = PatternParser.parseRow('V2: pb');
      final s = row.elements.first as StitchElement;
      expect(s.quantity, 1);
    });

    test('varios elementos separados por coma', () {
      final row = PatternParser.parseRow('R3: 2pb, aum, 3pa');
      expect(row.elements, hasLength(3));
      expect((row.elements[0] as StitchElement).type, 'pb');
      expect((row.elements[1] as StitchElement).type, 'aum');
      expect((row.elements[2] as StitchElement).quantity, 3);
    });

    test('bloque [..]xN', () {
      final row = PatternParser.parseRow('R4: [2pb, 1aum]x6');
      expect(row.elements, hasLength(1));
      final b = row.elements.first as BlockElement;
      expect(b.multiplier, 6);
      expect(b.stitches, hasLength(2));
      expect(b.stitches[0].type, 'pb');
      expect(b.stitches[1].type, 'aum');
    });

    test('total entre paréntesis se acepta y descarta', () {
      // El parser no valida la suma; solo verifica sintaxis.
      final row = PatternParser.parseRow('R5: 6pb (6)');
      expect(row.number, 5);
      expect(row.elements, hasLength(1));
    });

    test('acepta marcadores minúsculos r/v', () {
      expect(() => PatternParser.parseRow('r10: pb'), returnsNormally);
      expect(() => PatternParser.parseRow('v10: pb'), returnsNormally);
    });

    test('acepta x mayúscula en bloques', () {
      final row = PatternParser.parseRow('R1: [pb]X4');
      expect((row.elements.first as BlockElement).multiplier, 4);
    });
  });

  group('PatternParser.parseRow — errores de sintaxis', () {
    test('línea vacía', () {
      expect(
        () => PatternParser.parseRow(''),
        throwsA(isA<PatternParseException>()),
      );
    });

    test('marcador inválido (no R/V)', () {
      expect(
        () => PatternParser.parseRow('X1: pb'),
        throwsA(isA<PatternParseException>()),
      );
    });

    test('falta número de vuelta', () {
      expect(
        () => PatternParser.parseRow('R: pb'),
        throwsA(isA<PatternParseException>()),
      );
    });

    test('falta ":"', () {
      expect(
        () => PatternParser.parseRow('R1 pb'),
        throwsA(isA<PatternParseException>()),
      );
    });

    test('bloques anidados no permitidos', () {
      expect(
        () => PatternParser.parseRow('R1: [[pb]x2]x3'),
        throwsA(isA<PatternParseException>()),
      );
    });

    test('bloque sin multiplicador "x"', () {
      expect(
        () => PatternParser.parseRow('R1: [pb]'),
        throwsA(isA<PatternParseException>()),
      );
    });

    test('cantidad sin código de punto', () {
      expect(
        () => PatternParser.parseRow('R1: 3, pb'),
        throwsA(isA<PatternParseException>()),
      );
    });
  });

  group('PatternParser.parseAll', () {
    test('ignora líneas vacías y comentarios "#"', () {
      const text = '''
# nota: arrancar magic ring
R1: 6pb

R2: [aum]x6
''';
      final (rows, errors) = PatternParser.parseAll(text);
      expect(rows, hasLength(2));
      expect(errors, isEmpty);
    });

    test('recolecta errores sin abortar el resto', () {
      const text = 'R1: 6pb\nX bad line\nR2: pb';
      final (rows, errors) = PatternParser.parseAll(text);
      expect(rows, hasLength(2));
      expect(errors, hasLength(1));
    });

    test('preserva el índice de línea original', () {
      const text = '\n\nR1: pb\n\nR2: aum';
      final (rows, _) = PatternParser.parseAll(text);
      expect(rows[0].sourceLineIndex, 2);
      expect(rows[1].sourceLineIndex, 4);
    });
  });
}
