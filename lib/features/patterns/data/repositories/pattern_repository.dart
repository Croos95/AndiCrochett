import 'dart:async';
import 'package:andicrochett/database_helper.dart';
import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';

/// Repositorio de Patrones usando SQLite de forma directa
class PatternRepository {
  PatternRepository({DatabaseHelper? dbHelper})
      : _db = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  // ─────────────────────────────────────────────────────────────────────────
  // Streams (Flujos de datos en tiempo real simulados)
  // ─────────────────────────────────────────────────────────────────────────

  Stream<List<PatternModel>> watchAll() async* {
    yield await _db.getAllPatterns();
    yield* _streamWithRefresh(() => _db.getAllPatterns());
  }

  Stream<List<PatternModel>> watchByUser(String userId) async* {
    yield await _db.getPatternsByUser(userId);
    yield* _streamWithRefresh(() => _db.getPatternsByUser(userId));
  }

  Stream<List<PatternModel>> watchByDesign(int designId) async* {
    yield await _db.getPatternsByDesign(designId);
    yield* _streamWithRefresh(() => _db.getPatternsByDesign(designId));
  }

  Stream<PatternModel?> watchById(int id) async* {
    yield await _db.getPatternById(id);
    yield* _streamWithRefresh(() => _db.getPatternById(id));
  }

  // Helper para streams con refresh periódico
  Stream<T> _streamWithRefresh<T>(Future<T> Function() fetch) async* {
    while (true) {
      await Future.delayed(const Duration(milliseconds: 500));
      yield await fetch();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fetch methods (Consultas únicas)
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<PatternModel>> fetchAll() => _db.getAllPatterns();

  Future<List<PatternModel>> fetchByUser(String userId) =>
      _db.getPatternsByUser(userId);

  Future<List<PatternModel>> fetchByDesign(int designId) =>
      _db.getPatternsByDesign(designId);

  Future<PatternModel?> fetchById(int id) => _db.getPatternById(id);

  // ─────────────────────────────────────────────────────────────────────────
  // CRUD methods (Escritura y borrado)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> create(PatternModel pattern) async {
    await _db.createPattern(pattern.toMap());
  }

  Future<void> update(PatternModel pattern) async {
    if (pattern.id == null) throw Exception('El patrón no tiene ID');
    await _db.updatePattern(pattern.toMap());
  }

  Future<void> delete(int id) => _db.deletePattern(id);

  Future<void> deleteByDesign(int designId) => _db.deletePatternsByDesign(designId);

  Future<int> countByDesign(int designId) async {
    final patterns = await _db.getPatternsByDesign(designId);
    return patterns.length;
  }
}