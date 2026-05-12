import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:andicrochett/database_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CatalogSettingsModel
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class CatalogSettingsModel {
  const CatalogSettingsModel({
    this.id,
    required this.userId,
    this.isPublic = false,
    this.featuredProducts = const [],
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  final int? id;
  final String userId;
  final bool isPublic;
  final List<String> featuredProducts;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'usuario_id': userId,
    'es_publico': isPublic ? 1 : 0,
    'productos_destacados': jsonEncode(featuredProducts),
    'fecha_creacion': createdAt.toIso8601String(),
    'fecha_actualizacion': updatedAt.toIso8601String(),
  };

  factory CatalogSettingsModel.fromMap(Map<String, dynamic> map) {
    final productsJson = map['productos_destacados'] as String? ?? '[]';
    final List<dynamic> decodedProducts = jsonDecode(productsJson);

    return CatalogSettingsModel(
      id: map['id'] as int?,
      userId: map['usuario_id'] as String? ?? '',
      isPublic: (map['es_publico'] as int? ?? 0) == 1,
      featuredProducts: decodedProducts.cast<String>(),
      createdAt: DateTime.tryParse(map['fecha_creacion'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['fecha_actualizacion'] as String? ?? '') ?? DateTime.now(),
    );
  }

  CatalogSettingsModel copyWith({
    int? id,
    String? userId,
    bool? isPublic,
    List<String>? featuredProducts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      CatalogSettingsModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        isPublic: isPublic ?? this.isPublic,
        featuredProducts: featuredProducts ?? this.featuredProducts,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  void addFeaturedProduct(String productId) {
    if (!featuredProducts.contains(productId)) {
      (featuredProducts as List<String>).add(productId);
    }
  }

  void removeFeaturedProduct(String productId) {
    (featuredProducts as List<String>).remove(productId);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Repository
// ─────────────────────────────────────────────────────────────────────────────

abstract class LandingRepository {
  Stream<CatalogSettingsModel?> watchCatalog(String userId);
  Future<CatalogSettingsModel?> getCatalog(String userId);
  Future<void> updateCatalog(CatalogSettingsModel catalog);
  Future<void> togglePublicCatalog(String userId, bool isPublic);
  Future<void> addFeaturedProduct(String userId, String productId);
  Future<void> removeFeaturedProduct(String userId, String productId);
}

class LandingRepositoryImpl extends LandingRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  @override
  Stream<CatalogSettingsModel?> watchCatalog(String userId) async* {
    // Initial load
    final settings = await _db.getCatalogSettings(userId);
    yield settings != null ? CatalogSettingsModel.fromMap(settings) : null;

    // Listen to changes (simulated with periodic check)
    while (true) {
      await Future.delayed(Duration(milliseconds: 500));
      final updated = await _db.getCatalogSettings(userId);
      yield updated != null ? CatalogSettingsModel.fromMap(updated) : null;
    }
  }

  @override
  Future<CatalogSettingsModel?> getCatalog(String userId) async {
    final settings = await _db.getCatalogSettings(userId);
    return settings != null ? CatalogSettingsModel.fromMap(settings) : null;
  }

  @override
  Future<void> updateCatalog(CatalogSettingsModel catalog) async {
    await _db.updateCatalogSettings(
      catalog.userId,
      {
        'es_publico': catalog.isPublic ? 1 : 0,
        'productos_destacados': jsonEncode(catalog.featuredProducts),
      },
    );
  }

  @override
  Future<void> togglePublicCatalog(String userId, bool isPublic) async {
    final existing = await getCatalog(userId);
    if (existing != null) {
      final updated = existing.copyWith(isPublic: isPublic);
      await updateCatalog(updated);
    } else {
      final newSettings = CatalogSettingsModel(
        userId: userId,
        isPublic: isPublic,
        createdAt: DateTime.now(),
      );
      await updateCatalog(newSettings);
    }
  }

  @override
  Future<void> addFeaturedProduct(String userId, String productId) async {
    final existing = await getCatalog(userId);
    if (existing != null) {
      if (!existing.featuredProducts.contains(productId)) {
        final updated = existing.copyWith(
          featuredProducts: [...existing.featuredProducts, productId],
        );
        await updateCatalog(updated);
      }
    } else {
      final newSettings = CatalogSettingsModel(
        userId: userId,
        featuredProducts: [productId],
        createdAt: DateTime.now(),
      );
      await updateCatalog(newSettings);
    }
  }

  @override
  Future<void> removeFeaturedProduct(String userId, String productId) async {
    final existing = await getCatalog(userId);
    if (existing != null) {
      final updated = existing.copyWith(
        featuredProducts: existing.featuredProducts
            .where((id) => id != productId)
            .toList(),
      );
      await updateCatalog(updated);
    }
  }
}
