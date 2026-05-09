import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:andicrochett/features/auth/data/models/user_model.dart';

/// [AuthService] orquesta operaciones de auth que tocan más de una fuente
/// de datos (FirebaseAuth + Firestore 'users' collection).
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _db.collection('users');

  /// Crea el documento de perfil en 'users/{uid}' al completar el registro.
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
    await _usersCol.doc(user.uid).set(model.toMap());
  }

  /// Actualiza el displayName en FirebaseAuth y en Firestore.
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await user.updateDisplayName(name);
    await _usersCol.doc(user.uid).update({
      'displayName': name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Elimina la cuenta del usuario y su documento de Firestore.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Eliminar documento de perfil
    await _usersCol.doc(user.uid).delete();
    // Eliminar cuenta de FirebaseAuth
    await user.delete();
  }

  /// Obtiene el perfil del usuario actual desde Firestore.
  Future<UserModel?> getCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _usersCol.doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  /// Stream del perfil del usuario actual.
  Stream<UserModel?> watchProfile(String uid) {
    return _usersCol
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromDoc(doc) : null);
  }
}
