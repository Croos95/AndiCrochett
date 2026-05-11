import 'package:flutter/foundation.dart';
import 'dart:convert';

//lib/features/auth/data/models/user_model.dart
@immutable
class UserSettings {
  final String theme;
  final String language;
  final bool notifications;

  const UserSettings({
    this.theme = 'light',
    this.language = 'es',
    this.notifications = true,
  });

  // Convertimos a Map para guardar en un solo campo de texto en SQLite
  Map<String, dynamic> toMap() => {
    'theme': theme,
    'language': language,
    'notifications': notifications,
  };

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      theme: map['theme'] ?? 'light',
      language: map['language'] ?? 'es',
      notifications: map['notifications'] == 1 || map['notifications'] == true,
    );
  }
}

/// Perfil extendido del usuario almacenado en SQLite.
@immutable
class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.photoUrl = '',
    this.authProvider = 'email',
    required this.createdAt,
    required this.updatedAt,
    this.settings = const UserSettings(),
  });

  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String authProvider;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserSettings settings;
  // ── Serialización para SQLite ──────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'display_name': displayName,
    'photo_url': photoUrl,
    'auth_provider': authProvider,
    'fecha_creacion': createdAt.toIso8601String(),
    'fecha_actualizacion': updatedAt.toIso8601String(),
    'settings': jsonEncode(settings.toMap()), // Guardamos como String
  };

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Decodificamos el JSON de settings si existe
    UserSettings s = const UserSettings();
    if (map['settings'] != null) {
      try {
        s = UserSettings.fromMap(jsonDecode(map['settings']));
      } catch (_) {}
    }

    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['display_name'] as String? ?? '',
      photoUrl: map['photo_url'] as String? ?? '',
      authProvider: map['auth_provider'] as String? ?? 'email',
      createdAt: _parseDate(map['fecha_creacion']),
      updatedAt: _parseDate(map['fecha_actualizacion']),
      settings: s,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  //el copyWith para facilitar actualizaciones parciales del perfil
  //osea que si solo quiero cambiar el displayName, no tengo que pasar todo lo demás
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? authProvider,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserSettings? settings,
  }) => UserModel(
    uid: uid ?? this.uid,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    authProvider: authProvider ?? this.authProvider,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    settings: settings ?? this.settings,
  );

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, displayName: $displayName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email;

  @override
  int get hashCode => uid.hashCode ^ email.hashCode;
}
