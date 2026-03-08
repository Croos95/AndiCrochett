import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:andicrochett/features/landing_connection/data/models/catalog_settings_model.dart';

/// Repositorio Firestore para la configuración del catálogo público.
///
/// Colección: `catalog_settings/{userId}` (un doc por usuario).
class LandingRepository {
  final _col = FirebaseFirestore.instance.collection('catalog_settings');

  /// Devuelve un stream reactivo de la configuración del catálogo del usuario.
  /// Si el documento no existe, emite [CatalogSettings.empty].
  Stream<CatalogSettings> watchCatalog(String userId) {
    return _col.doc(userId).snapshots().map((snap) {
      if (!snap.exists) return CatalogSettings.empty(userId);
      return CatalogSettings.fromDoc(snap);
    });
  }

  /// Obtiene la configuración actual una sola vez.
  Future<CatalogSettings> getCatalog(String userId) async {
    final snap = await _col.doc(userId).get();
    if (!snap.exists) return CatalogSettings.empty(userId);
    return CatalogSettings.fromDoc(snap);
  }

  /// Crea o actualiza la configuración completa del catálogo.
  Future<void> updateCatalog(CatalogSettings settings) {
    return _col.doc(settings.userId).set(
          settings.toMap(),
          SetOptions(merge: true),
        );
  }

  /// Activa o desactiva el catálogo público sin modificar el resto.
  Future<void> togglePublicCatalog(String userId, bool enabled) {
    return _col.doc(userId).set({
      'isPublicCatalogEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Agrega un producto a los destacados.
  Future<void> addFeaturedProduct(String userId, String productId) {
    return _col.doc(userId).update({
      'featuredProducts': FieldValue.arrayUnion([productId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Quita un producto de los destacados.
  Future<void> removeFeaturedProduct(String userId, String productId) {
    return _col.doc(userId).update({
      'featuredProducts': FieldValue.arrayRemove([productId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
