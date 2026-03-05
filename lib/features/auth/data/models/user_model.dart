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

// ignore: unused_import — se necesitará al implementar fromDoc/toMap
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

  // TODO: Implementar toMap(), fromDoc(), copyWith().
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

  // TODO: Implementar toMap(), fromMap(), copyWith().
}
