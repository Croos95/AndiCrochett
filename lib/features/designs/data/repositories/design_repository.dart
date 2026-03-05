import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:andicrochett/features/designs/data/models/design_model.dart';

// =============================================================================
//  DesignRepository
//  Única fuente de verdad para CRUD en Firestore sobre la colección 'designs'.
// =============================================================================

class DesignRepository {
  DesignRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('designs');

  // ── Lectura ───────────────────────────────────────────────────────────────

  Stream<List<DesignDocument>> watchAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(DesignDocument.fromDoc).toList());

  Stream<List<DesignDocument>> watchByUser(String userId) => _col
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(DesignDocument.fromDoc).toList());

  Stream<DesignDocument?> watchById(String id) => _col
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? DesignDocument.fromDoc(s) : null);

  // ── Escritura ─────────────────────────────────────────────────────────────

  Future<String> create(DesignDocument design) async {
    final now = DateTime.now();
    final ref = await _col.add(
      design.copyWith(createdAt: now, updatedAt: now).toMap(),
    );
    return ref.id;
  }

  Future<void> update(DesignDocument design) async {
    await _col
        .doc(design.id)
        .update(design.copyWith(updatedAt: DateTime.now()).toMap());
  }

  Future<void> delete(String id) => _col.doc(id).delete();
}
