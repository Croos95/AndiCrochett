import 'package:andicrochett/database_helper.dart';
import 'package:andicrochett/features/designs/data/models/design_model.dart';

// =============================================================================
//  DesignRepository
//  Repositorio para CRUD en SQLite sobre la tabla 'designs'.
//  Usa polling (igual que PatternRepository) para evitar race conditions
//  con broadcast streams.
// =============================================================================

class DesignRepository {
  DesignRepository({DatabaseHelper? dbHelper})
      : _db = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<List<DesignModel>> watchByUser(String userId) async* {
    yield await _fetchDesignsByUser(userId);
    yield* _streamWithRefresh(() => _fetchDesignsByUser(userId));
  }

  Stream<DesignModel?> watchById(int id) async* {
    yield await _db.getDesignById(id);
    yield* _streamWithRefresh(() => _db.getDesignById(id));
  }

  Stream<T> _streamWithRefresh<T>(Future<T> Function() fetch) async* {
    while (true) {
      await Future.delayed(const Duration(milliseconds: 500));
      yield await fetch();
    }
  }

  // ── Lectura ───────────────────────────────────────────────────────────────

  Future<List<DesignModel>> getAll() async {
    try {
      return await _db.getAllDesigns();
    } catch (e) {
      throw Exception('Error al obtener diseños: $e');
    }
  }

  Future<List<DesignModel>> _fetchDesignsByUser(String userId) async {
    try {
      final all = await _db.getAllDesigns();
      return all.where((d) => d.userId == userId).toList();
    } catch (e) {
      throw Exception('Error al obtener diseños del usuario: $e');
    }
  }

  Future<DesignModel?> getById(int id) async {
    try {
      return await _db.getDesignById(id);
    } catch (e) {
      throw Exception('Error al obtener el diseño #$id: $e');
    }
  }

  // ── Escritura ─────────────────────────────────────────────────────────────

  Future<void> create(DesignModel design) async {
    try {
      if (design.userId.isEmpty) {
        throw Exception('El diseño debe tener un usuario válido.');
      }
      await _db.createDesign(design);
    } catch (e) {
      throw Exception('Error al crear el diseño: $e');
    }
  }

  Future<void> update(DesignModel design) async {
    try {
      if (design.id == null) {
        throw Exception('No se puede actualizar un diseño sin ID.');
      }
      await _db.updateDesign(design);
    } catch (e) {
      throw Exception('Error al actualizar el diseño: $e');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _db.deleteDesign(id);
    } catch (e) {
      throw Exception('Error al eliminar el diseño: $e');
    }
  }

  // Las páginas llaman a dispose(); se mantiene como no-op para compatibilidad.
  void dispose() {}
}
