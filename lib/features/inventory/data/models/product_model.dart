import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de producto con serialización Firestore.
class ProductModel {
  final String id;
  final String userId;
  final String name;
  final String imageUrl;
  final String category;
  final String colorHex;
  final String weight;
  final int currentStock;
  final int totalStock;
  final String status; // available | low_stock | out_of_stock
  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductModel({
    required this.id,
    this.userId = '',
    required this.name,
    this.imageUrl = '',
    required this.category,
    required this.colorHex,
    required this.weight,
    required this.currentStock,
    required this.totalStock,
    required this.status,
    this.isPublic = true,
    this.createdAt,
    this.updatedAt,
  });

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Etiqueta legible del status.
  String get statusLabel => switch (status) {
        'available' => 'OK',
        'low_stock' => 'BAJO STOCK',
        'out_of_stock' => 'AGOTADO',
        'full' => 'LLENO',
        'reorder' => 'REORDENAR',
        _ => status.toUpperCase(),
      };

  /// Ratio de stock (0.0 – 1.0).
  double get stockRatio =>
      totalStock == 0 ? 0 : (currentStock / totalStock).clamp(0.0, 1.0);

  // ── Firestore serialization ─────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'imageUrl': imageUrl,
        'category': category,
        'color': colorHex,
        'weight': weight,
        'currentStock': currentStock,
        'totalStock': totalStock,
        'status': status,
        'isPublic': isPublic,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      category: map['category'] as String? ?? '',
      colorHex: map['color'] as String? ?? '#FFFFFF',
      weight: map['weight'] as String? ?? '',
      currentStock: map['currentStock'] as int? ?? 0,
      totalStock: map['totalStock'] as int? ?? 0,
      status: map['status'] as String? ?? 'available',
      isPublic: map['isPublic'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory ProductModel.fromDocument(DocumentSnapshot doc) {
    return ProductModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  // ── copyWith ────────────────────────────────────────────────────────────

  ProductModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? imageUrl,
    String? category,
    String? colorHex,
    String? weight,
    int? currentStock,
    int? totalStock,
    String? status,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      colorHex: colorHex ?? this.colorHex,
      weight: weight ?? this.weight,
      currentStock: currentStock ?? this.currentStock,
      totalStock: totalStock ?? this.totalStock,
      status: status ?? this.status,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Datos de prueba ─────────────────────────────────────────────────────

  static List<ProductModel> get sampleProducts => [
        const ProductModel(
          id: 'p1',
          name: 'Algodón Premium',
          imageUrl: '',
          category: 'Madeja',
          colorHex: '#E9967A',
          weight: '100g',
          currentStock: 45,
          totalStock: 50,
          status: 'available',
        ),
        const ProductModel(
          id: 'p2',
          name: 'Lana Merino',
          imageUrl: '',
          category: 'Madeja',
          colorHex: '#F5F5DC',
          weight: '50g',
          currentStock: 5,
          totalStock: 100,
          status: 'low_stock',
        ),
        const ProductModel(
          id: 'p3',
          name: 'Trapillo Soft',
          imageUrl: '',
          category: 'Madeja',
          colorHex: '#808080',
          weight: '500g',
          currentStock: 20,
          totalStock: 20,
          status: 'full',
        ),
        const ProductModel(
          id: 'p4',
          name: 'Hilo de Seda',
          imageUrl: '',
          category: 'Madeja',
          colorHex: '#FFFACD',
          weight: '25g',
          currentStock: 12,
          totalStock: 60,
          status: 'reorder',
        ),
        const ProductModel(
          id: 'p5',
          name: 'Lana Gruesa',
          imageUrl: '',
          category: 'Ovillo',
          colorHex: '#C98B5A',
          weight: '200g',
          currentStock: 0,
          totalStock: 30,
          status: 'out_of_stock',
        ),
        const ProductModel(
          id: 'p6',
          name: 'Aguja Crochet 4mm',
          imageUrl: '',
          category: 'Herramientas',
          colorHex: '#BDBDBD',
          weight: '15g',
          currentStock: 3,
          totalStock: 5,
          status: 'low_stock',
        ),
        const ProductModel(
          id: 'p7',
          name: 'Hilo Acrílico Pastel',
          imageUrl: '',
          category: 'Madeja',
          colorHex: '#FFB6C1',
          weight: '100g',
          currentStock: 30,
          totalStock: 30,
          status: 'full',
        ),
      ];
}
