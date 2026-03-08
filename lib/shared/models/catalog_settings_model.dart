import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de configuración del catálogo público (landing).
class CatalogSettingsModel {
  final String userId;
  final bool isPublicCatalogEnabled;
  final String businessName;
  final Map<String, String> contactInfo;
  final List<String> featuredProducts;
  final List<String> featuredPatterns;
  final DateTime? updatedAt;

  const CatalogSettingsModel({
    required this.userId,
    this.isPublicCatalogEnabled = false,
    this.businessName = '',
    this.contactInfo = const {},
    this.featuredProducts = const [],
    this.featuredPatterns = const [],
    this.updatedAt,
  });

  // ── Firestore serialization ─────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'isPublicCatalogEnabled': isPublicCatalogEnabled,
        'businessName': businessName,
        'contactInfo': contactInfo,
        'featuredProducts': featuredProducts,
        'featuredPatterns': featuredPatterns,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory CatalogSettingsModel.fromMap(
      String userId, Map<String, dynamic> map) {
    return CatalogSettingsModel(
      userId: userId,
      isPublicCatalogEnabled: map['isPublicCatalogEnabled'] as bool? ?? false,
      businessName: map['businessName'] as String? ?? '',
      contactInfo:
          Map<String, String>.from(map['contactInfo'] as Map? ?? {}),
      featuredProducts:
          List<String>.from(map['featuredProducts'] as List? ?? []),
      featuredPatterns:
          List<String>.from(map['featuredPatterns'] as List? ?? []),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory CatalogSettingsModel.fromDocument(DocumentSnapshot doc) {
    return CatalogSettingsModel.fromMap(
        doc.id, doc.data() as Map<String, dynamic>);
  }

  // ── copyWith ────────────────────────────────────────────────────────────

  CatalogSettingsModel copyWith({
    String? userId,
    bool? isPublicCatalogEnabled,
    String? businessName,
    Map<String, String>? contactInfo,
    List<String>? featuredProducts,
    List<String>? featuredPatterns,
    DateTime? updatedAt,
  }) {
    return CatalogSettingsModel(
      userId: userId ?? this.userId,
      isPublicCatalogEnabled:
          isPublicCatalogEnabled ?? this.isPublicCatalogEnabled,
      businessName: businessName ?? this.businessName,
      contactInfo: contactInfo ?? this.contactInfo,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      featuredPatterns: featuredPatterns ?? this.featuredPatterns,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
