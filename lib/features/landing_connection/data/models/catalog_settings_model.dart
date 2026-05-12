import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Configuración del catálogo público del usuario.
///
/// Se almacena en SQLite en la tabla 'catalog_settings'.
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

  factory CatalogSettings.fromMap(Map<String, dynamic> map) {
    List<String> decodeList(String key) {
      final val = map[key];
      if (val != null && val.toString().isNotEmpty) {
        try {
          final decoded = jsonDecode(val.toString()) as List;
          return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return [];
    }

    return CatalogSettings(
      userId: map['usuario_id'] as String? ?? '',
      isPublicCatalogEnabled: (map['es_publico'] as int? ?? 0) == 1,
      businessName: map['nombre_negocio'] as String? ?? '',
      contactEmail: map['email_contacto'] as String? ?? '',
      contactPhone: map['telefono_contacto'] as String? ?? '',
      contactInstagram: map['instagram_contacto'] as String? ?? '',
      featuredProducts: decodeList('productos_destacados'),
      featuredPatterns: decodeList('patrones_destacados'),
      updatedAt: map['fecha_actualizacion'] != null
          ? DateTime.tryParse(map['fecha_actualizacion'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'usuario_id': userId,
    'es_publico': isPublicCatalogEnabled ? 1 : 0,
    'nombre_negocio': businessName,
    'email_contacto': contactEmail,
    'telefono_contacto': contactPhone,
    'instagram_contacto': contactInstagram,
    'productos_destacados': jsonEncode(featuredProducts),
    'patrones_destacados': jsonEncode(featuredPatterns),
    // No enviamos fecha_creacion aquí para que el dbHelper la maneje
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
  }) => CatalogSettings(
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
