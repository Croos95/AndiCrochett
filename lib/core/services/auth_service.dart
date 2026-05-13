import 'package:firebase_auth/firebase_auth.dart';
import 'package:andicrochett/features/auth/data/models/user_model.dart';
import 'package:andicrochett/database_helper.dart';

//lib/core/services/auth_service.dart
/// [AuthService] orquesta operaciones de auth que tocan más de una fuente
/// de datos (FirebaseAuth + SQLite 'users' table).
class AuthService {
  AuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = DatabaseHelper.instance;

  final FirebaseAuth _auth;
  final DatabaseHelper _db;

  /// Crea el documento de perfil en SQLite al completar el registro.
  Future<void> createUserProfile(User user, {String? authProvider}) async {
    final now = DateTime.now();
    final providerId =
        authProvider ??
        (user.providerData.isNotEmpty
            ? user.providerData.first.providerId
            : 'email');
    final model = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
      authProvider: providerId == 'google.com' ? 'google' : providerId,
      createdAt: now,
      updatedAt: now,
    );
    await _db.addUser(model);
  }

  /// Actualiza el displayName en FirebaseAuth y en SQLite.
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await user.updateDisplayName(name);
    await _db.updateUser(
      UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: name,
        photoUrl: user.photoURL ?? '',
        authProvider: 'email',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Elimina la cuenta del usuario y su registro de SQLite.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Eliminar registro de perfil
    await _db.deleteUser(user.uid);
    // Eliminar cuenta de FirebaseAuth
    await user.delete();
  }

  /// Obtiene el perfil del usuario actual desde SQLite.
  Future<UserModel?> getCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final map = await _db.getUserByUid(user.uid);
    return map != null ? UserModel.fromMap(map) : null;
  }

  /// Obtiene el perfil del usuario por UID desde SQLite.
  Future<UserModel?> getUserProfile(String uid) async {
    final map = await _db.getUserByUid(uid);
    return map != null ? UserModel.fromMap(map) : null;
  }

  Stream<UserModel?> watchProfile(String uid) async* {
    if (uid.isEmpty) {
      yield null;
      return;
    }
    // Obtenemos el perfil inicial
    final userMap = await _db.getUserByUid(uid);
    if (userMap != null) {
      yield UserModel.fromMap(userMap);
    } else {
      yield null;
    }
  }
}
