import 'package:flutter/foundation.dart';

/// Modelo del cliente optimizado para SQLite
@immutable
class ClientModel {
  const ClientModel({
    this.id,
    required this.name,
    this.email = '',
    this.phone = '',
    this.address = '',
    this.createdAt,
  });

  final int? id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final DateTime? createdAt;

  // ── Métodos de copia ──────────────────────────────────────────────────────

  ClientModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    DateTime? createdAt,
  }) =>
      ClientModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        createdAt: createdAt ?? this.createdAt,
      );

  // ── Serialización para SQLite ─────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'nombre': name,
    'email': email,
    'telefono': phone,
    'direccion': address,
  };

  /// Convierte desde Map de SQLite a ClientModel
  factory ClientModel.fromMap(Map<String, dynamic> map) => ClientModel(
    id: map['id'] as int?,
    name: map['nombre'] as String? ?? '',
    email: map['email'] as String? ?? '',
    phone: map['telefono'] as String? ?? '',
    address: map['direccion'] as String? ?? '',
    createdAt: DateTime.now(),
  );

  factory ClientModel.empty() => const ClientModel(name: '');

  @override
  String toString() => 'ClientModel(id: $id, name: $name, email: $email)';
}
