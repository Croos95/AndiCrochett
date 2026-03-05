import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PatternRepository
//  Única fuente de verdad para CRUD en Firestore sobre la colección 'patterns'.
// ─────────────────────────────────────────────────────────────────────────────

class PatternRepository {
  PatternRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('patterns');

  // ── Lectura ───────────────────────────────────────────────────────────────

  /// Stream de TODOS los patrones ordenados por fecha de creación, más reciente primero.
  Stream<List<PatternDocument>> watchAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PatternDocument.fromDoc).toList());
  }

  /// Stream de patrones que pertenecen a un usuario específico.
  Stream<List<PatternDocument>> watchByUser(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PatternDocument.fromDoc).toList());
  }

  /// Stream de un único documento de patrón por ID.
  /// Emite null cuando el documento no existe.
  Stream<PatternDocument?> watchById(String id) {
    return _col
        .doc(id)
        .snapshots()
        .map((snap) => snap.exists ? PatternDocument.fromDoc(snap) : null);
  }

  /// Obtiene un único patrón por ID en una sola lectura.
  Future<PatternDocument?> fetchById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return PatternDocument.fromDoc(doc);
  }

  // ── Escritura ─────────────────────────────────────────────────────────────

  /// Crea un nuevo patrón. Devuelve el ID de documento generado.
  Future<String> create(PatternDocument pattern) async {
    final now = DateTime.now();
    final data = pattern.copyWith(createdAt: now, updatedAt: now).toMap();
    final ref = await _col.add(data);
    return ref.id;
  }

  /// Actualiza un patrón existente por ID.
  Future<void> update(PatternDocument pattern) async {
    final data = pattern.copyWith(updatedAt: DateTime.now()).toMap();
    await _col.doc(pattern.id).update(data);
  }

  /// Elimina un patrón por ID.
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  // ── Helpers con contexto de diseño ────────────────────────────────────────

  /// Stream de patrones que pertenecen a un diseño específico (filtrado por usuario).
  Stream<List<PatternDocument>> watchByDesign(
    String designId, {
    required String userId,
  }) {
    return _col
        .where('designId', isEqualTo: designId)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PatternDocument.fromDoc).toList());
  }

  /// Stream con el conteo de patrones de un diseño (filtrado por usuario).
  Stream<int> countByDesign(String designId, {required String userId}) {
    return _col
        .where('designId', isEqualTo: designId)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Elimina TODOS los patrones que pertenecen a un diseño (borrado en lote).
  /// El filtro [userId] garantiza que solo se borren los patrones del propietario,
  /// evitando borrados accidentales entre usuarios.
  Future<void> deleteByDesign(String designId, {required String userId}) async {
    final snap = await _col
        .where('designId', isEqualTo: designId)
        .where('userId', isEqualTo: userId)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
