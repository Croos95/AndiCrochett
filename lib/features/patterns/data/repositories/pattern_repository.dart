import 'dart:async';
import 'package:flutter/foundation.dart';
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

  Stream<List<PatternModel>> watchAll() =>
      _refresh(() => _db.getAllPatterns()).distinct(_listEq);

  Stream<List<PatternModel>> watchByUser(String userId) =>
      _refresh(() => _db.getPatternsByUser(userId)).distinct(_listEq);

  Stream<List<PatternModel>> watchByDesign(int designId) =>
      _refresh(() => _db.getPatternsByDesign(designId)).distinct(_listEq);

  Stream<PatternModel?> watchById(int id) =>
      _refresh(() => _db.getPatternById(id)).distinct(_singleEq);

  Stream<T> _refresh<T>(Future<T> Function() fetch) async* {
    yield await fetch();
    while (true) {
      await Future.delayed(const Duration(milliseconds: 500));
      yield await fetch();
    }
  }

  // Comparadores: evitan re-emisiones cuando el contenido no cambió,
  // así StreamBuilder no reconstruye el grid en cada poll de 500ms.
  static bool _listEq(List<PatternModel> a, List<PatternModel> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!mapEquals(a[i].toMap(), b[i].toMap())) return false;
    }
    return true;
  }

  static bool _singleEq(PatternModel? a, PatternModel? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return mapEquals(a.toMap(), b.toMap());
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

  Future<void> deleteByDesign(int designId) =>
      _db.deletePatternsByDesign(designId);

  Future<int> countByDesign(int designId) async {
    final patterns = await _db.getPatternsByDesign(designId);
    return patterns.length;
  }
}
