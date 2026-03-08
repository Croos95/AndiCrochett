import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Configuración del catálogo público del usuario.
///
/// Se almacena en Firestore bajo 'catalog_settings/{userId}'.
@immutable
class CatalogSettings {
  const CatalogSettings({
    required this.userId,
    required this.isPublicCatalogEnabled,
    required this.businessName,
    required this.contactEmail,
    required this.contactPhone,
    required this.contactInstagram,
    this.featuredProducts = const [],
    this.featuredPatterns = const [],
    this.updatedAt,
  });

  final String userId;
  final bool isPublicCatalogEnabled;
  final String businessName;
  final String contactEmail;
  final String contactPhone;
  final String contactInstagram;
  final List<String> featuredProducts;
  final List<String> featuredPatterns;
  final DateTime? updatedAt;

  factory CatalogSettings.empty(String userId) => CatalogSettings(
        userId: userId,
        isPublicCatalogEnabled: false,
        businessName: '',
        contactEmail: '',
        contactPhone: '',
        contactInstagram: '',
      );

  factory CatalogSettings.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final contact = d['contactInfo'] as Map<String, dynamic>? ?? {};
    return CatalogSettings(
      userId: doc.id,
      isPublicCatalogEnabled: d['isPublicCatalogEnabled'] as bool? ?? false,
      businessName: d['businessName'] as String? ?? '',
      contactEmail: contact['email'] as String? ?? '',
      contactPhone: contact['phone'] as String? ?? '',
      contactInstagram: contact['instagram'] as String? ?? '',
      featuredProducts: List<String>.from(d['featuredProducts'] ?? []),
      featuredPatterns: List<String>.from(d['featuredPatterns'] ?? []),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'isPublicCatalogEnabled': isPublicCatalogEnabled,
        'businessName': businessName,
        'contactInfo': {
          'email': contactEmail,
          'phone': contactPhone,
          'instagram': contactInstagram,
        },
        'featuredProducts': featuredProducts,
        'featuredPatterns': featuredPatterns,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  CatalogSettings copyWith({
    String? userId,
    bool? isPublicCatalogEnabled,
    String? businessName,
    String? contactEmail,
    String? contactPhone,
    String? contactInstagram,
    List<String>? featuredProducts,
    List<String>? featuredPatterns,
    DateTime? updatedAt,
  }) =>
      CatalogSettings(
        userId: userId ?? this.userId,
        isPublicCatalogEnabled:
            isPublicCatalogEnabled ?? this.isPublicCatalogEnabled,
        businessName: businessName ?? this.businessName,
        contactEmail: contactEmail ?? this.contactEmail,
        contactPhone: contactPhone ?? this.contactPhone,
        contactInstagram: contactInstagram ?? this.contactInstagram,
        featuredProducts: featuredProducts ?? this.featuredProducts,
        featuredPatterns: featuredPatterns ?? this.featuredPatterns,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
