import 'package:andicrochett/database_helper.dart';
import 'package:andicrochett/features/clients/data/models/client_model.dart';

/// Repositorio de Clientes usando SQLite
class ClientRepository {
  ClientRepository({DatabaseHelper? dbHelper})
      : _db = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  // ── Lectura ───────────────────────────────────────────────────────────────

  /// Obtiene todos los clientes.
  Future<List<ClientModel>> getAllClients() async {
    try {
      final results = await _db.getAllClients();
      return results.map((map) => ClientModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener clientes: $e');
    }
  }

  /// Obtiene un cliente por ID.
  Future<ClientModel?> getClientById(int id) async {
    try {
      final result = await _db.queryById(DatabaseHelper.tableClients, id);
      return result != null ? ClientModel.fromMap(result) : null;
    } catch (e) {
      throw Exception('Error al obtener cliente: $e');
    }
  }

  /// Busca clientes por nombre o email.
  Future<List<ClientModel>> searchClients(String query) async {
    try {
      final all = await getAllClients();
      final lowerQuery = query.toLowerCase();
      return all
          .where((c) =>
              c.name.toLowerCase().contains(lowerQuery) ||
              c.email.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar clientes: $e');
    }
  }

  // ── Escritura ─────────────────────────────────────────────────────────────

  /// Crea un nuevo cliente.
  Future<int> createClient(ClientModel client) async {
    try {
      return await _db.addClient(
        client.name,
        client.email.isNotEmpty ? client.email : null,
        client.phone.isNotEmpty ? client.phone : null,
        client.address.isNotEmpty ? client.address : null,
      );
    } catch (e) {
      throw Exception('Error al crear cliente: $e');
    }
  }

  /// Actualiza un cliente.
  Future<int> updateClient(ClientModel client) async {
    try {
      if (client.id == null) throw Exception('El cliente debe tener un ID');
      return await _db.updateClient(
        client.id!,
        nombre: client.name,
        email: client.email.isNotEmpty ? client.email : null,
        telefono: client.phone.isNotEmpty ? client.phone : null,
        direccion: client.address.isNotEmpty ? client.address : null,
      );
    } catch (e) {
      throw Exception('Error al actualizar cliente: $e');
    }
  }

  /// Elimina un cliente.
  Future<int> deleteClient(int id) async {
    try {
      return await _db.deleteClient(id);
    } catch (e) {
      throw Exception('Error al eliminar cliente: $e');
    }
  }
}
