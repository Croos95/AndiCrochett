import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:andicrochett/features/auth/data/models/user_model.dart';

/// Servicio de autenticación con Firebase Auth.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Usuario actual de Firebase Auth (null si no autenticado).
  User? get currentUser => _auth.currentUser;

  /// Stream de cambios de autenticación.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// UID del usuario actual o null.
  String? get uid => _auth.currentUser?.uid;

  //  Email & Password 

  /// Registrar con email y contraseña.
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    String displayName = '',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;

    if (displayName.isNotEmpty) {
      await user.updateDisplayName(displayName);
    }

    final userModel = UserModel(
      uid: user.uid,
      email: email,
      displayName: displayName,
      photoUrl: user.photoURL ?? '',
      authProvider: 'email',
    );

    await _db.collection('users').doc(user.uid).set(userModel.toMap());
    return userModel;
  }

  /// Iniciar sesión con email y contraseña.
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _getOrCreateUserDoc(credential.user!);
  }

  //  Sign Out 

  /// Cerrar sesión.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  //  Password Reset 

  /// Enviar email de recuperación de contraseña.
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  //  User Document 

  /// Obtener el UserModel del usuario actual desde Firestore.
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDocument(doc);
  }

  /// Actualizar datos del perfil del usuario.
  Future<void> updateUserProfile(UserModel userModel) async {
    await _db.collection('users').doc(userModel.uid).update(userModel.toMap());
  }

  //  Private helpers 

  Future<UserModel> _getOrCreateUserDoc(User user) async {
    final docRef = _db.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      return UserModel.fromDocument(doc);
    }

    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
      authProvider: 'email',
    );
    await docRef.set(userModel.toMap());
    return userModel;
  }
}
