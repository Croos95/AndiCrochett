import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:andicrochett/core/config/env.dart';
import 'package:andicrochett/core/services/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CatalogSettingsModel
//  DEPRECATED: usa CatalogSettings en lib/features/landing_connection/data/
//  models/catalog_settings_model.dart. Esta clase se mantiene solo por
//  compatibilidad con código antiguo.
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
      createdAt:
          DateTime.tryParse(map['fecha_creacion'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['fecha_actualizacion'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  CatalogSettingsModel copyWith({
    int? id,
    String? userId,
    bool? isPublic,
    List<String>? featuredProducts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CatalogSettingsModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    isPublic: isPublic ?? this.isPublic,
    featuredProducts: featuredProducts ?? this.featuredProducts,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Repository — consume /api/catalog
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
  LandingRepositoryImpl({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  @override
  Stream<CatalogSettingsModel?> watchCatalog(String userId) async* {
    yield await getCatalog(userId);
    while (true) {
      await Future.delayed(Env.pollInterval);
      yield await getCatalog(userId);
    }
  }

  @override
  Future<CatalogSettingsModel?> getCatalog(String userId) async {
    try {
      final data = await _api.get('/catalog/me');
      if (data == null) return null;
      return CatalogSettingsModel.fromMap(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<void> updateCatalog(CatalogSettingsModel catalog) async {
    await _api.put('/catalog/me', body: {
      'es_publico': catalog.isPublic ? 1 : 0,
      'productos_destacados': jsonEncode(catalog.featuredProducts),
    });
  }

  @override
  Future<void> togglePublicCatalog(String userId, bool isPublic) async {
    final existing = await getCatalog(userId);
    if (existing != null) {
      await updateCatalog(existing.copyWith(isPublic: isPublic));
    } else {
      await updateCatalog(CatalogSettingsModel(
        userId: userId,
        isPublic: isPublic,
        createdAt: DateTime.now(),
      ));
    }
  }

  @override
  Future<void> addFeaturedProduct(String userId, String productId) async {
    final existing = await getCatalog(userId);
    if (existing != null) {
      if (existing.featuredProducts.contains(productId)) return;
      await updateCatalog(existing.copyWith(
        featuredProducts: [...existing.featuredProducts, productId],
      ));
    } else {
      await updateCatalog(CatalogSettingsModel(
        userId: userId,
        featuredProducts: [productId],
        createdAt: DateTime.now(),
      ));
    }
  }

  @override
  Future<void> removeFeaturedProduct(String userId, String productId) async {
    final existing = await getCatalog(userId);
    if (existing == null) return;
    await updateCatalog(existing.copyWith(
      featuredProducts: existing.featuredProducts
          .where((id) => id != productId)
          .toList(),
    ));
  }
}
