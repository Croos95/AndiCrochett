// =============================================================================
//  UserModel
//  DTO de Firestore para el perfil extendido del usuario.
//
//  Firebase Auth provee el UID, email y displayName básicos.
//  Este modelo mapea el documento 'users/{uid}' que contiene preferencias,
//  foto de perfil, fecha de creación y configuración de la aplicación.
//
//  Estado: PENDIENTE DE IMPLEMENTACIÓN.
//  Ver el documento sembrado en _FirebaseTestView para el esquema esperado.
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Perfil extendido almacenado en Firestore bajo 'users/{uid}'.
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

  // ── Serialización ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'authProvider': authProvider,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'settings': settings.toMap(),
  };

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: d['email'] as String? ?? '',
      displayName: d['displayName'] as String? ?? '',
      photoUrl: d['photoUrl'] as String? ?? '',
      authProvider: d['authProvider'] as String? ?? 'email',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      settings: d['settings'] != null
          ? UserSettings.fromMap(d['settings'] as Map<String, dynamic>)
          : const UserSettings(),
    );
  }

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
}

/// Preferencias del usuario almacenadas como sub-documento en 'settings'.
@immutable
class UserSettings {
  const UserSettings({
    this.theme = 'light',
    this.language = 'es',
    this.notifications = true,
  });

  final String theme;
  final String language;
  final bool notifications;

  Map<String, dynamic> toMap() => {
    'theme': theme,
    'language': language,
    'notifications': notifications,
  };

  factory UserSettings.fromMap(Map<String, dynamic> map) => UserSettings(
    theme: map['theme'] as String? ?? 'light',
    language: map['language'] as String? ?? 'es',
    notifications: map['notifications'] as bool? ?? true,
  );

  UserSettings copyWith({
    String? theme,
    String? language,
    bool? notifications,
  }) => UserSettings(
    theme: theme ?? this.theme,
    language: language ?? this.language,
    notifications: notifications ?? this.notifications,
  );
}
