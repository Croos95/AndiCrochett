import 'package:firebase_auth/firebase_auth.dart';
import 'package:andicrochett/features/auth/data/models/user_model.dart';

/// Orquestador de operaciones del perfil del usuario.
///
/// La fuente de verdad del perfil es **Firebase Auth**: `displayName`,
/// `photoURL`, `email`, `uid` y la fecha de creación viven en el token de
/// Firebase. Antes existía una tabla `usuarios` en SQLite local, pero la
/// migración al backend centralizado eliminó esa duplicación: hoy todos los
/// campos se derivan de `FirebaseAuth.currentUser`.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Construye un [UserModel] a partir del usuario actual de Firebase.
  UserModel? _profileFromUser(User? user, {String? authProviderOverride}) {
    if (user == null) return null;
    final providerId = authProviderOverride
        ?? (user.providerData.isNotEmpty
            ? user.providerData.first.providerId
            : 'email');
    final created = user.metadata.creationTime ?? DateTime.now();
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
      authProvider: providerId == 'google.com' ? 'google' : providerId,
      createdAt: created,
      updatedAt: user.metadata.lastSignInTime ?? created,
    );
  }

  /// Punto de entrada llamado al completar el registro. Hoy es un no-op
  /// porque Firebase Auth ya guarda toda la información del perfil.
  /// Se mantiene la firma por compatibilidad con código existente.
  Future<void> createUserProfile(User user, {String? authProvider}) async {
    // No-op: el perfil vive en Firebase Auth.
  }

  /// Actualiza el `displayName` en Firebase Auth.
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name);
    await user.reload();
  }

  /// Elimina la cuenta del usuario (Firebase Auth).
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.delete();
  }

  /// Devuelve el perfil del usuario autenticado (o `null` si no hay sesión).
  Future<UserModel?> getCurrentProfile() async {
    return _profileFromUser(_auth.currentUser);
  }

  /// Devuelve el perfil de un usuario específico por UID.
  ///
  /// Solo puede resolver el perfil del usuario actualmente autenticado;
  /// Firebase Auth no permite leer otras cuentas desde el cliente.
  Future<UserModel?> getUserProfile(String uid) async {
    final current = _auth.currentUser;
    if (current == null || current.uid != uid) return null;
    return _profileFromUser(current);
  }

  /// Stream del perfil. Reacciona a cambios de `authStateChanges` y a las
  /// actualizaciones que dispara `updateDisplayName`.
  Stream<UserModel?> watchProfile(String uid) async* {
    if (uid.isEmpty) {
      yield null;
      return;
    }
    yield _profileFromUser(_auth.currentUser);
    yield* _auth.userChanges().map(_profileFromUser);
  }
}
