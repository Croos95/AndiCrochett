import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, IconData, Icons;
import 'package:andicrochett/core/constants/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PatternDifficulty
// ─────────────────────────────────────────────────────────────────────────────

enum PatternDifficulty { beginner, intermediate, advanced, expert }

extension PatternDifficultyX on PatternDifficulty {
  String get label => switch (this) {
    PatternDifficulty.beginner => 'Principiante',
    PatternDifficulty.intermediate => 'Intermedio',
    PatternDifficulty.advanced => 'Avanzado',
    PatternDifficulty.expert => 'Experto',
  };

  Color get color => switch (this) {
    PatternDifficulty.beginner => AppColors.verdeOliva,
    PatternDifficulty.intermediate => AppColors.bronce,
    PatternDifficulty.advanced => AppColors.resaltado,
    PatternDifficulty.expert => AppColors.error,
  };

  static PatternDifficulty fromString(String v) => PatternDifficulty.values
      .firstWhere((e) => e.name == v, orElse: () => PatternDifficulty.beginner);
}

// ─────────────────────────────────────────────────────────────────────────────
//  PatternStatus
// ─────────────────────────────────────────────────────────────────────────────

enum PatternStatus { draft, finished }

extension PatternStatusX on PatternStatus {
  String get label => switch (this) {
    PatternStatus.draft => 'Borrador',
    PatternStatus.finished => 'Finalizado',
  };

  Color get color => switch (this) {
    PatternStatus.draft => AppColors.bronce,
    PatternStatus.finished => AppColors.verdeOliva,
  };

  IconData get icon => switch (this) {
    PatternStatus.draft => Icons.edit_outlined,
    PatternStatus.finished => Icons.check_circle_outline,
  };

  static PatternStatus fromString(String v) => PatternStatus.values.firstWhere(
    (e) => e.name == v,
    orElse: () => PatternStatus.draft,
  );
}

enum PatternType { circular, rows, mixed }

extension PatternTypeX on PatternType {
  /// Display label in Spanish.
  String get label => switch (this) {
    PatternType.circular => 'Circular',
    PatternType.rows => 'Filas',
    PatternType.mixed => 'Mixto',
  };

  /// Brand-consistent color for badges and chips.
  Color get color => switch (this) {
    PatternType.circular => AppColors.verdeOliva,
    PatternType.rows => AppColors.bronce,
    PatternType.mixed => AppColors.resaltado,
  };

  static PatternType fromString(String v) => PatternType.values.firstWhere(
    (e) => e.name == v,
    orElse: () => PatternType.circular,
  );
}

@immutable
class PatternError {
  const PatternError(this.row, this.message);

  final int row;
  final String message;

  @override
  String toString() => 'R$row: $message';
}

@immutable
class StitchDefinition {
  const StitchDefinition(this.produced, this.consumed);

  final int produced;
  final int consumed;
}

class StitchRegistry {
  static const Map<String, StitchDefinition> stitches = {
    "AM": StitchDefinition(0, 0),
    "pb": StitchDefinition(1, 1),
    "pma": StitchDefinition(1, 1),
    "pa": StitchDefinition(1, 1),
    // Cadena: no consume punto estructural de la vuelta anterior ni produce
    // uno nuevo contable — es puramente notacional/decorativa en el conteo.
    "cad": StitchDefinition(0, 0),
    "aum": StitchDefinition(2, 1),
    "aumtri": StitchDefinition(3, 1),
    "dis": StitchDefinition(1, 2),
    "dpa": StitchDefinition(1, 1),
    "tpa": StitchDefinition(1, 1),
    "pbub": StitchDefinition(1, 1),
    // Additional stitch types
    "pr": StitchDefinition(0, 1), // Punto recto (slip stitch)
    "vcad": StitchDefinition(1, 1), // Vuelta en cadena atrás
    "vcadf": StitchDefinition(1, 1), // Vuelta en cadena delantera
  };

  static bool exists(String key) => stitches.containsKey(key);
  static StitchDefinition get(String key) => stitches[key]!;
}

abstract class Element {}

class StitchElement extends Element {
  final String type;
  final int quantity;

  StitchElement(this.type, this.quantity);
}

class BlockElement extends Element {
  final List<StitchElement> stitches;
  final int multiplier;

  BlockElement(this.stitches, this.multiplier);
}

class RowPattern {
  final int number;
  final List<Element> elements;
  final int declaredTotal;
  int calculatedTotal = 0;

  RowPattern({
    required this.number,
    required this.elements,
    required this.declaredTotal,
  });
}

class CrochetPattern {
  final String name;
  final PatternType type;
  final List<RowPattern> rows;

  CrochetPattern({required this.name, required this.type, required this.rows});
}

class PatternParser {
  static final RegExp rowRegex = RegExp(r'^R(\d+):(.+)\((\d+)\)$');

  static final RegExp blockRegex = RegExp(r'\[(.*?)\]x(\d+)');

  static final RegExp stitchRegex = RegExp(r'(\d+)?([a-zA-Z]+)');

  static RowPattern parseRow(String input) {
    final match = rowRegex.firstMatch(input.trim());
    if (match == null) {
      throw Exception("Sintaxis inválida en fila");
    }

    final rowNumber = int.parse(match.group(1)!);
    final instruction = match.group(2)!.trim();
    final declaredTotal = int.parse(match.group(3)!);

    final elements = _parseInstruction(instruction);

    return RowPattern(
      number: rowNumber,
      elements: elements,
      declaredTotal: declaredTotal,
    );
  }

  static List<Element> _parseInstruction(String instruction) {
    List<Element> elements = [];

    final parts = instruction.split(",");

    for (var part in parts) {
      part = part.trim();

      final blockMatch = blockRegex.firstMatch(part);

      if (blockMatch != null) {
        final inside = blockMatch.group(1)!;
        final multiplier = int.parse(blockMatch.group(2)!);

        final stitches = _parseStitches(inside);
        elements.add(BlockElement(stitches, multiplier));
      } else {
        final stitches = _parseStitches(part);
        elements.addAll(stitches);
      }
    }

    return elements;
  }

  static List<StitchElement> _parseStitches(String input) {
    final matches = stitchRegex.allMatches(input);
    List<StitchElement> stitches = [];

    for (final match in matches) {
      final qty = match.group(1) != null ? int.parse(match.group(1)!) : 1;
      final type = match.group(2)!;

      if (!StitchRegistry.exists(type)) {
        throw Exception("Punto no reconocido: $type");
      }

      stitches.add(StitchElement(type, qty));
    }

    return stitches;
  }
}

class PatternEngine {
  static List<PatternError> validate(CrochetPattern pattern) {
    List<PatternError> errors = [];

    // Type-specific stitch restrictions
    if (pattern.type == PatternType.circular) {
      for (final row in pattern.rows) {
        for (final element in row.elements) {
          void checkType(String type) {
            if (type == 'vcad' || type == 'vcadf') {
              errors.add(
                PatternError(
                  row.number,
                  '$type no está permitido en patrones circulares',
                ),
              );
            }
          }

          if (element is StitchElement) checkType(element.type);
          if (element is BlockElement) {
            for (final s in element.stitches) checkType(s.type);
          }
        }
      }
    }

    int previousAvailable = 0;

    for (final row in pattern.rows) {
      int produced = 0;
      int consumed = 0;

      // ── Anillo mágico (AM) restrictions ───────────────────────────────
      // AM must appear only once, only in row 1, and only as the very
      // first element of that row. It is also forbidden inside blocks.
      int amCount = 0;
      for (int i = 0; i < row.elements.length; i++) {
        final el = row.elements[i];
        if (el is StitchElement && el.type == 'AM') {
          amCount++;
          if (row.number != 1) {
            errors.add(
              PatternError(
                row.number,
                'El anillo mágico (AM) solo se permite en R1',
              ),
            );
          } else if (i != 0) {
            errors.add(
              PatternError(
                row.number,
                'El anillo mágico (AM) debe ser el primer elemento de R1',
              ),
            );
          }
          if (amCount > 1) {
            errors.add(
              PatternError(
                row.number,
                'El anillo mágico (AM) solo puede usarse una vez',
              ),
            );
          }
        }
        if (el is BlockElement) {
          for (final s in el.stitches) {
            if (s.type == 'AM') {
              errors.add(
                PatternError(
                  row.number,
                  'El anillo mágico (AM) no puede estar dentro de un bloque',
                ),
              );
            }
          }
        }
      }

      for (final element in row.elements) {
        if (element is StitchElement) {
          final def = StitchRegistry.get(element.type);

          produced += def.produced * element.quantity;
          consumed += def.consumed * element.quantity;
        }

        if (element is BlockElement) {
          if (element.multiplier <= 1) {
            errors.add(
              PatternError(
                row.number,
                "Multiplicador inválido (debe ser mayor a 1)",
              ),
            );
          }

          int blockProduced = 0;
          int blockConsumed = 0;

          for (final stitch in element.stitches) {
            final def = StitchRegistry.get(stitch.type);

            blockProduced += def.produced * stitch.quantity;
            blockConsumed += def.consumed * stitch.quantity;
          }

          produced += blockProduced * element.multiplier;
          consumed += blockConsumed * element.multiplier;
        }
      }

      if (row.number > 1 && consumed > previousAvailable) {
        errors.add(
          PatternError(
            row.number,
            "No hay suficientes puntos disponibles para consumir",
          ),
        );
      }

      row.calculatedTotal = produced;

      if (row.calculatedTotal != row.declaredTotal) {
        errors.add(
          PatternError(
            row.number,
            "Total declarado (${row.declaredTotal}) no coincide con calculado (${row.calculatedTotal})",
          ),
        );
      }

      previousAvailable = row.calculatedTotal;
    }

    return errors;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PatternDocument — Firestore DTO that wraps the domain model.
//  The pattern instructions are stored as plain text (rawText);
//  parsing and validation are done on the client side.
// ─────────────────────────────────────────────────────────────────────────────

class PatternDocument {
  PatternDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.rawText,
    required this.designId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.difficulty = PatternDifficulty.beginner,
    this.suggestedMaterial = '',
    this.hookSize = '',
    this.status = PatternStatus.draft,
  });

  final String id;
  final String name;
  final PatternType type;

  /// ID of the DesignDocument this pattern belongs to.
  final String designId;

  final PatternDifficulty difficulty;
  final String suggestedMaterial;
  final String hookSize;
  final PatternStatus status;

  /// Multi-line text: each non-empty line is one row instruction.
  /// Format: R<n>: <instructions> (<total>)
  /// Example: "R1: AM, 6pb (6)"
  final String rawText;

  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Derived (cached) ────────────────────────────────────────────────────
  //  Both parse and validate are computed lazily on first access and cached
  //  for the lifetime of this immutable instance, avoiding repeated DSL
  //  parsing on every widget rebuild.

  late final CrochetPattern? _parsed = _computeParse();
  late final List<PatternError> _errors = _computeErrors();

  /// Parses rawText into the domain model.
  /// Returns null if the text is empty or entirely unparseable.
  CrochetPattern? tryParse() => _parsed;

  /// Validates the full pattern and returns all errors (parse + logic).
  List<PatternError> validate() => _errors;

  CrochetPattern? _computeParse() {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .toList();
    if (lines.isEmpty) return null;
    final rows = <RowPattern>[];
    for (final line in lines) {
      try {
        rows.add(PatternParser.parseRow(line));
      } catch (_) {
        // Silently skip — editor surfaces per-line errors via validate().
      }
    }
    return rows.isEmpty
        ? null
        : CrochetPattern(name: name, type: type, rows: rows);
  }

  List<PatternError> _computeErrors() {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .toList();
    if (lines.isEmpty) return const [];

    final parseErrors = <PatternError>[];
    final rows = <RowPattern>[];
    for (int i = 0; i < lines.length; i++) {
      try {
        rows.add(PatternParser.parseRow(lines[i]));
      } catch (e) {
        parseErrors.add(PatternError(i + 1, e.toString()));
      }
    }

    if (rows.isEmpty) return parseErrors;
    final pattern = CrochetPattern(name: name, type: type, rows: rows);
    return [...parseErrors, ...PatternEngine.validate(pattern)];
  }

  int get rowCount =>
      rawText.split('\n').where((l) => l.trim().isNotEmpty).length;

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type.name,
    'rawText': rawText,
    'designId': designId,
    'userId': userId,
    'difficulty': difficulty.name,
    'suggestedMaterial': suggestedMaterial,
    'hookSize': hookSize,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory PatternDocument.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PatternDocument(
      id: doc.id,
      name: d['name'] as String? ?? '',
      type: PatternTypeX.fromString(d['type'] as String? ?? 'circular'),
      rawText: d['rawText'] as String? ?? '',
      designId: d['designId'] as String? ?? '',
      userId: d['userId'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      difficulty: PatternDifficultyX.fromString(
        d['difficulty'] as String? ?? 'beginner',
      ),
      suggestedMaterial: d['suggestedMaterial'] as String? ?? '',
      hookSize: d['hookSize'] as String? ?? '',
      status: PatternStatusX.fromString(d['status'] as String? ?? 'draft'),
    );
  }

  factory PatternDocument.empty() => PatternDocument(
    id: '',
    name: '',
    type: PatternType.circular,
    rawText: '',
    designId: '',
    userId: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  PatternDocument copyWith({
    String? id,
    String? name,
    PatternType? type,
    String? rawText,
    String? designId,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    PatternDifficulty? difficulty,
    String? suggestedMaterial,
    String? hookSize,
    PatternStatus? status,
  }) {
    return PatternDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      rawText: rawText ?? this.rawText,
      designId: designId ?? this.designId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      difficulty: difficulty ?? this.difficulty,
      suggestedMaterial: suggestedMaterial ?? this.suggestedMaterial,
      hookSize: hookSize ?? this.hookSize,
      status: status ?? this.status,
    );
  }
}
