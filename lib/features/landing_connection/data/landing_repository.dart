import 'dart:async';
import 'dart:convert';

import 'package:andicrochett/core/config/env.dart';
import 'package:andicrochett/core/services/api_client.dart';
import 'package:andicrochett/features/landing_connection/data/models/catalog_settings_model.dart';

/// Repositorio del catálogo público. Habla con el backend `/api/catalog`.
class LandingRepository {
  LandingRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<CatalogSettings> watchCatalog(String userId) async* {
    yield await getCatalog(userId);
    while (true) {
      await Future.delayed(Env.pollInterval);
      yield await getCatalog(userId);
    }
  }

  // ── Lectura ───────────────────────────────────────────────────────────────

  Future<CatalogSettings> getCatalog(String userId) async {
    try {
      final data = await _api.get('/catalog/me');
      if (data == null) return CatalogSettings.empty(userId);
      return CatalogSettings.fromMap(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return CatalogSettings.empty(userId);
      rethrow;
    }
  }

  // ── Escritura ─────────────────────────────────────────────────────────────

  Future<void> updateCatalog(CatalogSettings settings) async {
    await _api.put('/catalog/me', body: {
      'es_publico': settings.isPublicCatalogEnabled ? 1 : 0,
      'nombre_negocio': settings.businessName,
      'email_contacto': settings.contactEmail,
      'telefono_contacto': settings.contactPhone,
      'instagram_contacto': settings.contactInstagram,
      'productos_destacados': jsonEncode(settings.featuredProducts),
      'patrones_destacados': jsonEncode(settings.featuredPatterns),
    });
  }

  Future<void> togglePublicCatalog(String userId, bool enabled) async {
    final current = await getCatalog(userId);
    final updated = current.copyWith(
      isPublicCatalogEnabled: enabled,
      updatedAt: DateTime.now(),
    );
    await updateCatalog(updated);
  }

  Future<void> addFeaturedProduct(String userId, String productId) async {
    final current = await getCatalog(userId);
    if (current.featuredProducts.contains(productId)) return;
    final list = List<String>.from(current.featuredProducts)..add(productId);
    await updateCatalog(current.copyWith(
      featuredProducts: list,
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> removeFeaturedProduct(String userId, String productId) async {
    final current = await getCatalog(userId);
    if (!current.featuredProducts.contains(productId)) return;
    final list = current.featuredProducts.where((id) => id != productId).toList();
    await updateCatalog(current.copyWith(
      featuredProducts: list,
      updatedAt: DateTime.now(),
    ));
  }
}
