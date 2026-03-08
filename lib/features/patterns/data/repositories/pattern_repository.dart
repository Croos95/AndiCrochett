import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';

/// Repositorio de patrones  CRUD sobre la colección patterns en Firestore.
class PatternRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _collection => _db.collection('patterns');

  /// Obtener todos los patrones del usuario.
  Future<List<PatternModel>> getPatterns(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((d) => PatternModel.fromDocument(d)).toList();
  }

  /// Stream en tiempo real de patrones del usuario.
  Stream<List<PatternModel>> watchPatterns(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PatternModel.fromDocument(d)).toList());
  }

  /// Obtener un patrón por ID.
  Future<PatternModel?> getPattern(String patternId) async {
    final doc = await _collection.doc(patternId).get();
    if (!doc.exists) return null;
    return PatternModel.fromDocument(doc);
  }

  /// Crear un patrón nuevo.
  Future<String> createPattern(PatternModel pattern) async {
    final doc = await _collection.add(pattern.toMap());
    return doc.id;
  }

  /// Actualizar un patrón existente.
  Future<void> updatePattern(PatternModel pattern) async {
    await _collection.doc(pattern.id).update(pattern.toMap());
  }

  /// Eliminar un patrón.
  Future<void> deletePattern(String patternId) async {
    await _collection.doc(patternId).delete();
  }

  /// Obtener patrones públicos (para galería).
  Future<List<PatternModel>> getPublicPatterns() async {
    final snapshot = await _collection
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((d) => PatternModel.fromDocument(d)).toList();
  }
}
