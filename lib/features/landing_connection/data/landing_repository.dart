import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:andicrochett/shared/models/catalog_settings_model.dart';

/// Repositorio del catálogo público / landing.
class LandingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _collection => _db.collection('catalog_settings');

  /// Obtener configuración del catálogo del usuario.
  Future<CatalogSettingsModel?> getCatalogSettings(String userId) async {
    final doc = await _collection.doc(userId).get();
    if (!doc.exists) return null;
    return CatalogSettingsModel.fromDocument(doc);
  }

  /// Crear o actualizar la configuración del catálogo.
  Future<void> saveCatalogSettings(CatalogSettingsModel settings) async {
    await _collection.doc(settings.userId).set(
          settings.toMap(),
          SetOptions(merge: true),
        );
  }

  /// Actualizar productos destacados.
  Future<void> updateFeaturedProducts(
      String userId, List<String> productIds) async {
    await _collection.doc(userId).update({
      'featuredProducts': productIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Actualizar patrones destacados.
  Future<void> updateFeaturedPatterns(
      String userId, List<String> patternIds) async {
    await _collection.doc(userId).update({
      'featuredPatterns': patternIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Activar/desactivar catálogo público.
  Future<void> togglePublicCatalog(String userId, bool enabled) async {
    await _collection.doc(userId).update({
      'isPublicCatalogEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
