import 'package:andicrochett/core/config/env.dart';
import 'package:andicrochett/core/services/api_client.dart';
import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';

/// Repositorio de Patrones contra la API REST.
///
/// Los datos son compartidos entre todos los usuarios autenticados;
/// `watchByUser` se mantiene por compatibilidad con las páginas pero devuelve
/// todos los patrones (el userId queda como audit trail en cada registro).
class PatternRepository {
  PatternRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  static const _basePath = '/patterns';

  // ─────────────────────────────────────────────────────────────────────────
  // Streams (polling con intervalo de Env.pollInterval)
  // ─────────────────────────────────────────────────────────────────────────

  Stream<List<PatternModel>> watchAll() async* {
    yield await fetchAll();
    yield* _refresh(fetchAll);
  }

  Stream<List<PatternModel>> watchByUser(String _) async* {
    yield await fetchAll();
    yield* _refresh(fetchAll);
  }

  Stream<List<PatternModel>> watchByDesign(int designId) async* {
    yield await fetchByDesign(designId);
    yield* _refresh(() => fetchByDesign(designId));
  }

  Stream<PatternModel?> watchById(int id) async* {
    yield await fetchById(id);
    yield* _refresh(() => fetchById(id));
  }

  Stream<T> _refresh<T>(Future<T> Function() fetch) async* {
    while (true) {
      await Future.delayed(Env.pollInterval);
      yield await fetch();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fetch
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<PatternModel>> fetchAll() async {
    final data = await _api.get(_basePath) as List<dynamic>;
    return data.map((m) => PatternModel.fromMap(m as Map<String, dynamic>)).toList();
  }

  Future<List<PatternModel>> fetchByUser(String _) => fetchAll();

  Future<List<PatternModel>> fetchByDesign(int designId) async {
    final data = await _api.get(
      _basePath,
      query: {'designId': designId},
    ) as List<dynamic>;
    return data.map((m) => PatternModel.fromMap(m as Map<String, dynamic>)).toList();
  }

  Future<PatternModel?> fetchById(int id) async {
    try {
      final data = await _api.get('$_basePath/$id') as Map<String, dynamic>;
      return PatternModel.fromMap(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CRUD
  // ─────────────────────────────────────────────────────────────────────────

  Future<PatternModel> create(PatternModel pattern) async {
    final body = _toBody(pattern);
    final data = await _api.post(_basePath, body: body) as Map<String, dynamic>;
    return PatternModel.fromMap(data);
  }

  Future<PatternModel> update(PatternModel pattern) async {
    if (pattern.id == null) throw Exception('El patrón no tiene ID');
    final body = _toBody(pattern);
    final data = await _api.put('$_basePath/${pattern.id}', body: body) as Map<String, dynamic>;
    return PatternModel.fromMap(data);
  }

  Future<void> delete(int id) => _api.delete('$_basePath/$id');

  /// Borra todos los patrones de un diseño. El backend cascade-elimina los
  /// patrones cuando se borra el diseño padre, así que aquí solo hacemos
  /// el borrado manual cuando se necesite (por ejemplo, mantener el design
  /// pero limpiar sus patrones).
  Future<void> deleteByDesign(int designId) async {
    final patterns = await fetchByDesign(designId);
    for (final p in patterns) {
      if (p.id != null) await delete(p.id!);
    }
  }

  Future<int> countByDesign(int designId) async {
    final patterns = await fetchByDesign(designId);
    return patterns.length;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Map<String, dynamic> _toBody(PatternModel pattern) => {
    'nombre': pattern.name,
    'tipo': pattern.type.sqliteValue,
    'design_id': pattern.designId,
    'dificultad': pattern.difficulty.sqliteValue,
    'material_sugerido': pattern.suggestedMaterial,
    'tamano_gancho': pattern.hookSize,
    'estado': pattern.status.sqliteValue,
    'texto_patron': pattern.rawText,
  };
}
