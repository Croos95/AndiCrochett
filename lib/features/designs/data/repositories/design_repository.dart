import 'package:andicrochett/core/config/env.dart';
import 'package:andicrochett/core/services/api_client.dart';
import 'package:andicrochett/features/designs/data/models/design_model.dart';

// =============================================================================
//  DesignRepository
//  CRUD de diseños contra la API REST. Los datos son compartidos entre todos
//  los usuarios autenticados: `watchByUser(userId)` se mantiene por compatibilidad
//  pero devuelve todos los diseños (el userId pasa a ser solo audit trail).
// =============================================================================

class DesignRepository {
  DesignRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  static const _basePath = '/designs';

  // ── Streams (polling con intervalo de Env.pollInterval) ──────────────────

  Stream<List<DesignModel>> watchByUser(String _) async* {
    yield await getAll();
    yield* _refresh(getAll);
  }

  Stream<DesignModel?> watchById(int id) async* {
    yield await getById(id);
    yield* _refresh(() => getById(id));
  }

  Stream<T> _refresh<T>(Future<T> Function() fetch) async* {
    while (true) {
      await Future.delayed(Env.pollInterval);
      yield await fetch();
    }
  }

  // ── Lectura ───────────────────────────────────────────────────────────────

  Future<List<DesignModel>> getAll() async {
    final data = await _api.get(_basePath) as List<dynamic>;
    return data.map((m) => DesignModel.fromMap(m as Map<String, dynamic>)).toList();
  }

  Future<DesignModel?> getById(int id) async {
    try {
      final data = await _api.get('$_basePath/$id') as Map<String, dynamic>;
      return DesignModel.fromMap(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  // ── Escritura ─────────────────────────────────────────────────────────────

  Future<DesignModel> create(DesignModel design) async {
    if (design.name.trim().isEmpty) {
      throw Exception('El diseño debe tener un nombre.');
    }
    final data = await _api.post(
      _basePath,
      body: {'nombre': design.name, 'descripcion': design.description},
    ) as Map<String, dynamic>;
    return DesignModel.fromMap(data);
  }

  Future<DesignModel> update(DesignModel design) async {
    if (design.id == null) {
      throw Exception('No se puede actualizar un diseño sin ID.');
    }
    final data = await _api.put(
      '$_basePath/${design.id}',
      body: {'nombre': design.name, 'descripcion': design.description},
    ) as Map<String, dynamic>;
    return DesignModel.fromMap(data);
  }

  Future<void> delete(int id) => _api.delete('$_basePath/$id');

  void dispose() {}
}
