/// Modelo local de producto para la UI.
/// No depende de Firestore – solo es un DTO para las vistas.
class ProductModel {
  final String id;
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

  // ── copyWith ────────────────────────────────────────────────────────────

  ProductModel copyWith({
    String? id,
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
