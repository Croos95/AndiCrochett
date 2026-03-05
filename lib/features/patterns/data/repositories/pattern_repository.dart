import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PatternRepository
//  Single source of truth for Firestore CRUD on the 'patterns' collection.
// ─────────────────────────────────────────────────────────────────────────────

class PatternRepository {
  PatternRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('patterns');

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Stream of ALL patterns ordered by creation date, newest first.
  Stream<List<PatternDocument>> watchAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PatternDocument.fromDoc).toList());
  }

  /// Stream of patterns belonging to a specific user.
  Stream<List<PatternDocument>> watchByUser(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PatternDocument.fromDoc).toList());
  }

  /// Stream of a single pattern document by ID.
  /// Emits null when the document does not exist.
  Stream<PatternDocument?> watchById(String id) {
    return _col
        .doc(id)
        .snapshots()
        .map((snap) => snap.exists ? PatternDocument.fromDoc(snap) : null);
  }

  /// Fetch a single pattern by ID once.
  Future<PatternDocument?> fetchById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return PatternDocument.fromDoc(doc);
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Create a new pattern. Returns the generated document ID.
  Future<String> create(PatternDocument pattern) async {
    final now = DateTime.now();
    final data = pattern.copyWith(createdAt: now, updatedAt: now).toMap();
    final ref = await _col.add(data);
    return ref.id;
  }

  /// Update an existing pattern by ID.
  Future<void> update(PatternDocument pattern) async {
    final data = pattern.copyWith(updatedAt: DateTime.now()).toMap();
    await _col.doc(pattern.id).update(data);
  }

  /// Delete a pattern by ID.
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  // ── Design-scoped helpers ─────────────────────────────────────────────────

  /// Stream of patterns belonging to a specific design (and user).
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

  /// Stream of the pattern count for a given design.
  Stream<int> countByDesign(String designId) {
    return _col
        .where('designId', isEqualTo: designId)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Delete ALL patterns that belong to a given design (batch delete).
  Future<void> deleteByDesign(String designId) async {
    final snap = await _col.where('designId', isEqualTo: designId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
