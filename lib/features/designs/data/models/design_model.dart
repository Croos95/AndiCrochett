import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// =============================================================================
//  DesignDocument — Firestore DTO for a crochet design.
//  A design groups one or more CrochetPatterns together.
//  Firestore collection: 'designs'
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

  /// Display name of the design, e.g. "Amigurumi de osito".
  final String name;

  /// Optional free-text description of the design.
  final String description;

  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Serialization ─────────────────────────────────────────────────────────

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
