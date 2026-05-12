import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, IconData, Icons;
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/features/patterns/utils/stitch_registry.dart';
//lib/features/designs/data/models/design_model.dart
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

  String get sqliteValue => name;

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

  String get sqliteValue => name;

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

  String get sqliteValue => name;

  static PatternType fromString(String v) => PatternType.values.firstWhere(
    (e) => e.name == v,
    orElse: () => PatternType.circular,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  PatternModel para SQLite
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class PatternModel {
  const PatternModel({
    this.id,
    required this.name,
    required this.type,
    required this.designId,
    this.difficulty = PatternDifficulty.beginner,
    this.suggestedMaterial = '',
    this.hookSize = '',
    this.status = PatternStatus.draft,
    this.rawText = '',
    required this.userId,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  final int? id;
  final String name;
  final PatternType type;
  final int designId;
  final PatternDifficulty difficulty;
  final String suggestedMaterial;
  final String hookSize;
  final PatternStatus status;
  final String rawText;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Serialización ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'nombre': name,
    'tipo': type.sqliteValue,
    'design_id': designId,
    'dificultad': difficulty.sqliteValue,
    'material_sugerido': suggestedMaterial,
    'tamano_gancho': hookSize,
    'estado': status.sqliteValue,
    'texto_patron': rawText,
    'usuario_id': userId,
    'fecha_creacion': createdAt.toIso8601String(),
    'fecha_actualizacion': updatedAt.toIso8601String(),
  };

  factory PatternModel.fromMap(Map<String, dynamic> map) {
    return PatternModel(
      id: map['id'] as int?,
      name: map['nombre'] as String? ?? '',
      type: PatternTypeX.fromString(map['tipo'] as String? ?? 'rows'),
      designId: map['design_id'] as int? ?? 0,
      difficulty: PatternDifficultyX.fromString(map['dificultad'] as String? ?? 'beginner'),
      suggestedMaterial: map['material_sugerido'] as String? ?? '',
      hookSize: map['tamano_gancho'] as String? ?? '',
      status: PatternStatusX.fromString(map['estado'] as String? ?? 'draft'),
      rawText: map['texto_patron'] as String? ?? '',
      userId: map['usuario_id'] as String? ?? '',
      createdAt: DateTime.tryParse(map['fecha_creacion'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['fecha_actualizacion'] as String? ?? '') ?? DateTime.now(),
    );
  }

  // TODO: implementar validación real cuando PatternParser.parseRow() deje de
  // ser un stub. Debe parsear rawText vuelta por vuelta, acumular los errores
  // matemáticos (puntos producidos vs consumidos) y devolverlos como PatternError.
  // Mientras tanto, _liveErrors en PatternEditorPage y la comprobación pre-save
  // en _save() siempre reciben lista vacía, por lo que el bloqueo de guardado
  // por errores matemáticos nunca se activa.
  List<PatternError> validate() {
    if (rawText.isEmpty) return const [];
    // TODO: return PatternParser.validateAll(rawText);
    return const [];
  }
  /// Calcula el número de vueltas basándose en las líneas no vacías del texto crudo
  int get rowCount {
    if (rawText.isEmpty) return 0;
    return rawText.split('\n').where((l) => l.trim().isNotEmpty).length;
  }
  
  PatternModel copyWith({
    int? id,
    String? name,
    PatternType? type,
    int? designId,
    PatternDifficulty? difficulty,
    String? suggestedMaterial,
    String? hookSize,
    PatternStatus? status,
    String? rawText,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PatternModel(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        designId: designId ?? this.designId,
        difficulty: difficulty ?? this.difficulty,
        suggestedMaterial: suggestedMaterial ?? this.suggestedMaterial,
        hookSize: hookSize ?? this.hookSize,
        status: status ?? this.status,
        rawText: rawText ?? this.rawText,
        userId: userId ?? this.userId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
    /// Valida la sintaxis del texto del patrón
  
}
