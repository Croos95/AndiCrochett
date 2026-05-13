import 'package:flutter/foundation.dart';

// =============================================================================
//  DesignModel — Modelo para un diseño de crochet en SQLite.
//  Un diseño agrupa uno o más patrones de crochet.
//  Tabla SQLite: 'designs'
// =============================================================================

@immutable
class DesignModel {
  const DesignModel({
    this.id,
    required this.name,
    required this.description,
    required this.userId,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  final int? id;

  /// Nombre visible del diseño, p.ej. "Amigurumi de osito".
  final String name;

  /// Descripción libre y opcional del diseño.
  final String description;

  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Serialización ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'nombre': name,
    'descripcion': description,
    'usuario_id': userId,
    'fecha_creacion': createdAt.toIso8601String(),
    'fecha_actualizacion': updatedAt.toIso8601String(),
  };

  factory DesignModel.fromMap(Map<String, dynamic> map) {
    return DesignModel(
      id: map['id'] as int?,
      name: map['nombre'] as String? ?? '',
      description: map['descripcion'] as String? ?? '',
      userId: map['usuario_id'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['fecha_creacion'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['fecha_actualizacion'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory DesignModel.empty({required String userId}) => DesignModel(
    name: '',
    description: '',
    userId: userId,
    createdAt: DateTime.now(),
  );

  DesignModel copyWith({
    int? id,
    String? name,
    String? description,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DesignModel(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
