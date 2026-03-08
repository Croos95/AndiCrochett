import 'package:cloud_firestore/cloud_firestore.dart';

/// Celda individual del grid de un patrón.
class PatternCell {
  final int row;
  final int col;
  final String color;
  final String stitch; // sc, dc, hdc, ch, sl_st, etc.

  const PatternCell({
    required this.row,
    required this.col,
    required this.color,
    this.stitch = 'sc',
  });

  Map<String, dynamic> toMap() => {
        'row': row,
        'col': col,
        'color': color,
        'stitch': stitch,
      };

  factory PatternCell.fromMap(Map<String, dynamic> map) {
    return PatternCell(
      row: map['row'] as int? ?? 0,
      col: map['col'] as int? ?? 0,
      color: map['color'] as String? ?? '#FFFFFF',
      stitch: map['stitch'] as String? ?? 'sc',
    );
  }
}

/// Material usado en un patrón.
class PatternMaterial {
  final String name;
  final String quantity;

  const PatternMaterial({required this.name, required this.quantity});

  Map<String, dynamic> toMap() => {'name': name, 'quantity': quantity};

  factory PatternMaterial.fromMap(Map<String, dynamic> map) {
    return PatternMaterial(
      name: map['name'] as String? ?? '',
      quantity: map['quantity'] as String? ?? '',
    );
  }
}

/// Datos del grid (dimensiones + celdas).
class GridData {
  final int rows;
  final int columns;
  final List<PatternCell> cells;

  const GridData({
    this.rows = 10,
    this.columns = 10,
    this.cells = const [],
  });

  Map<String, dynamic> toMap() => {
        'rows': rows,
        'columns': columns,
        'cells': cells.map((c) => c.toMap()).toList(),
      };

  factory GridData.fromMap(Map<String, dynamic> map) {
    return GridData(
      rows: map['rows'] as int? ?? 10,
      columns: map['columns'] as int? ?? 10,
      cells: (map['cells'] as List<dynamic>?)
              ?.map((e) => PatternCell.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Modelo de patrón de crochet.
class PatternModel {
  final String id;
  final String userId;
  final String name;
  final String thumbnailUrl;
  final GridData gridData;
  final List<PatternMaterial> materials;
  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PatternModel({
    required this.id,
    required this.userId,
    required this.name,
    this.thumbnailUrl = '',
    this.gridData = const GridData(),
    this.materials = const [],
    this.isPublic = false,
    this.createdAt,
    this.updatedAt,
  });

  //  Firestore serialization 

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'thumbnailUrl': thumbnailUrl,
        'gridData': gridData.toMap(),
        'materials': materials.map((m) => m.toMap()).toList(),
        'isPublic': isPublic,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory PatternModel.fromMap(String id, Map<String, dynamic> map) {
    return PatternModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      gridData: map['gridData'] != null
          ? GridData.fromMap(map['gridData'] as Map<String, dynamic>)
          : const GridData(),
      materials: (map['materials'] as List<dynamic>?)
              ?.map((e) => PatternMaterial.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      isPublic: map['isPublic'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory PatternModel.fromDocument(DocumentSnapshot doc) {
    return PatternModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  //  copyWith 

  PatternModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? thumbnailUrl,
    GridData? gridData,
    List<PatternMaterial>? materials,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatternModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      gridData: gridData ?? this.gridData,
      materials: materials ?? this.materials,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
