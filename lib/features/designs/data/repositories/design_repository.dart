import 'dart:async';

import 'package:andicrochett/database_helper.dart';
import 'package:andicrochett/features/designs/data/models/design_model.dart';

// =============================================================================
//  DesignRepository
// Repositorio para CRUD en SQLite sobre la tabla 'designs'.
// =============================================================================

class DesignRepository {
  DesignRepository({DatabaseHelper? dbHelper})
      : _db = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;
  final _designsStreamController =
      StreamController<List<DesignModel>>.broadcast();

  Stream<List<DesignModel>> get designsStream => _designsStreamController.stream;

  // ── Lectura ───────────────────────────────────────────────────────────────

  /// Obtiene todos los diseños ordenados por fecha de creación.
  Future<List<DesignModel>> getAll() async {
    try {
      return await _db.getAllDesigns();
    } catch (e) {
      throw Exception('Error al obtener diseños: $e');
    }
  }

  /// Obtiene diseños filtrados por usuario como Stream.
  Stream<List<DesignModel>> watchByUser(String userId) async* {
    try {
      final initial = await _fetchDesignsByUser(userId);
      yield initial;
    } catch (e) {
      print('Error al cargar diseños iniciales: $e');
    }

    await for (final designs in _designsStreamController.stream) {
      yield designs.where((d) => d.userId == userId).toList();
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

  /// Obtiene un diseño específico por su ID.
  Future<DesignModel?> getById(int id) async {
    try {
      return await _db.getDesignById(id);
    } catch (e) {
      throw Exception('Error al obtener el diseño #$id: $e');
    }
  }

  // ── Escritura ─────────────────────────────────────────────────────────────

  /// Crea un nuevo diseño.
  Future<void> create(DesignModel design) async {
    try {
      if (design.userId.isEmpty) {
        throw Exception('El diseño debe tener un usuario válido.');
      }
      await _db.createDesign(design);
      await _refreshDesigns();
    } catch (e) {
      throw Exception('Error al crear el diseño: $e');
    }
  }

  /// Actualiza un diseño existente.
  Future<void> update(DesignModel design) async {
    try {
      if (design.id == null) {
        throw Exception('No se puede actualizar un diseño sin ID.');
      }
      await _db.updateDesign(design);
      await _refreshDesigns();
    } catch (e) {
      throw Exception('Error al actualizar el diseño: $e');
    }
  }

  /// Elimina un diseño.
  Future<void> delete(int id) async {
    try {
      await _db.deleteDesign(id);
      await _refreshDesigns();
    } catch (e) {
      throw Exception('Error al eliminar el diseño: $e');
    }
  }

  // ── Utilidades privadas ───────────────────────────────────────────────────

  Future<void> _refreshDesigns() async {
    final designs = await getAll();
    _designsStreamController.add(designs);
  }

  void dispose() {
    _designsStreamController.close();
  }
}
