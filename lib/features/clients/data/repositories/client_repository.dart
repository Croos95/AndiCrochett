import 'package:andicrochett/core/services/api_client.dart';
import 'package:andicrochett/features/clients/data/models/client_model.dart';

/// Repositorio de Clientes contra la API REST.
class ClientRepository {
  ClientRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  static const _basePath = '/clients';

  // ── Lectura ───────────────────────────────────────────────────────────────

  Future<List<ClientModel>> getAllClients() async {
    final data = await _api.get(_basePath) as List<dynamic>;
    return data.map((m) => ClientModel.fromMap(m as Map<String, dynamic>)).toList();
  }

  Future<ClientModel?> getClientById(int id) async {
    try {
      final data = await _api.get('$_basePath/$id') as Map<String, dynamic>;
      return ClientModel.fromMap(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Búsqueda client-side (el backend no expone endpoint de búsqueda para
  /// clientes). Mantiene la misma firma que la versión anterior.
  Future<List<ClientModel>> searchClients(String query) async {
    final all = await getAllClients();
    final q = query.toLowerCase();
    return all
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q))
        .toList();
  }

  // ── Escritura ─────────────────────────────────────────────────────────────

  Future<int> createClient(ClientModel client) async {
    final data = await _api.post(_basePath, body: _toBody(client)) as Map<String, dynamic>;
    return data['id'] as int? ?? 0;
  }

  Future<int> updateClient(ClientModel client) async {
    if (client.id == null) throw Exception('El cliente debe tener un ID');
    await _api.put('$_basePath/${client.id}', body: _toBody(client));
    return 1;
  }

  Future<int> deleteClient(int id) async {
    await _api.delete('$_basePath/$id');
    return 1;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _toBody(ClientModel c) => {
    'nombre': c.name,
    'email': c.email.isEmpty ? null : c.email,
    'telefono': c.phone.isEmpty ? null : c.phone,
    'direccion': c.address.isEmpty ? null : c.address,
  };
}
