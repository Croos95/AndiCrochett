import 'dart:async';
import 'package:andicrochett/database_helper.dart';
import 'package:andicrochett/features/landing_connection/data/models/catalog_settings_model.dart';

/// Repositorio SQLite para la configuración del catálogo público.
class LandingRepository {
  LandingRepository({DatabaseHelper? dbHelper})
    : _db = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  // ─────────────────────────────────────────────────────────────────────────
  // Streams (Flujos reactivos simulados)
  // ─────────────────────────────────────────────────────────────────────────

  Stream<CatalogSettings> watchCatalog(String userId) async* {
    yield await getCatalog(userId);
    yield* _streamWithRefresh(() => getCatalog(userId));
  }

  Stream<T> _streamWithRefresh<T>(Future<T> Function() fetch) async* {
    while (true) {
      await Future.delayed(const Duration(milliseconds: 500));
      yield await fetch();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Operaciones CRUD
  // ─────────────────────────────────────────────────────────────────────────

  Future<CatalogSettings> getCatalog(String userId) async {
    final map = await _db.getCatalogSettings(userId);

    if (map == null) return CatalogSettings.empty(userId);

    // Cambiamos fromDoc (que era de Firebase) por fromMap (para SQLite)
    return CatalogSettings.fromMap(map);
  }

  Future<void> updateCatalog(CatalogSettings settings) async {
    // Usaremos un método "upsert" (actualizar si existe, insertar si no existe)
    await _db.updateCatalogSettings(settings.userId, settings.toMap());
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

    // Evitamos duplicados manualmente
    if (!current.featuredProducts.contains(productId)) {
      final updatedList = List<String>.from(current.featuredProducts)
        ..add(productId);

      final updated = current.copyWith(
        featuredProducts: updatedList,
        updatedAt: DateTime.now(),
      );

      await updateCatalog(updated);
    }
  }

  Future<void> removeFeaturedProduct(String userId, String productId) async {
    final current = await getCatalog(userId);

    if (current.featuredProducts.contains(productId)) {
      final updatedList = List<String>.from(current.featuredProducts)
        ..remove(productId);

      final updated = current.copyWith(
        featuredProducts: updatedList,
        updatedAt: DateTime.now(),
      );

      await updateCatalog(updated);
    }
  }
}
