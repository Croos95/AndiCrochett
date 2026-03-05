import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// =============================================================================
//  DesignDocument — DTO de Firestore para un diseño de crochet.
//  Un diseño agrupa uno o más patrones de crochet.
//  Colección de Firestore: 'designs'
// =============================================================================

@immutable
class DesignDocument {
  const DesignDocument({
    required this.id,
    required this.name,
    required this.description,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// Nombre visible del diseño, p.ej. "Amigurumi de osito".
  final String name;

  /// Descripción libre y opcional del diseño.
  final String description;

  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Serialización ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'userId': userId,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory DesignDocument.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DesignDocument(
      id: doc.id,
      name: d['name'] as String? ?? '',
      description: d['description'] as String? ?? '',
      userId: d['userId'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory DesignDocument.empty() => DesignDocument(
    id: '',
    name: '',
    description: '',
    userId: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  DesignDocument copyWith({
    String? id,
    String? name,
    String? description,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DesignDocument(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
