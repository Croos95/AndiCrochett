import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AuthRepository
// ─────────────────────────────────────────────────────────────────────────────

class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  // ── Stream ────────────────────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Iniciar sesión con email + contraseña ─────────────────────────────────────────

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  // ── Registro con email + contraseña ────────────────────────────────────────

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) => _auth.createUserWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()..addScope('email');
      return _auth.signInWithPopup(provider);
    }

    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();

    try {
      final account = await googleSignIn.authenticate(
        scopeHint: const ['email'],
      );
      final credential = GoogleAuthProvider.credential(
        idToken: account.authentication.idToken,
      );
      return _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      final code = switch (e.code) {
        GoogleSignInExceptionCode.canceled => 'canceled',
        GoogleSignInExceptionCode.interrupted => 'network-request-failed',
        GoogleSignInExceptionCode.uiUnavailable => 'operation-not-allowed',
        GoogleSignInExceptionCode.providerConfigurationError =>
          'operation-not-allowed',
        GoogleSignInExceptionCode.clientConfigurationError =>
          'operation-not-allowed',
        GoogleSignInExceptionCode.unknownError => 'invalid-credential',
        _ => 'invalid-credential',
      };
      throw FirebaseAuthException(code: code, message: e.description);
    }
  }

  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.sendEmailVerification();
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ── Cerrar sesión ───────────────────────────────────────────────────────────────

  Future<void> signOut() => _auth.signOut();

  // ── Reset contraseña ────────────────────────────────────────────────────────

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // ── Mensajes de error ─────────────────────────────────────────

  static String messageFromCode(String code) => switch (code) {
    'user-not-found' => 'No existe una cuenta con ese correo.',
    'wrong-password' => 'Contraseña incorrecta.',
    'invalid-credential' => 'Correo o contraseña incorrectos.',
    'email-already-in-use' => 'Ese correo ya está registrado.',
    'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
    'invalid-email' => 'El formato del correo no es válido.',
    'canceled' => 'La acción fue cancelada.',
    'popup-closed-by-user' =>
      'Cerraste la ventana antes de completar el acceso.',
    'account-exists-with-different-credential' =>
      'Ese correo ya tiene otro método de acceso.',
    'operation-not-allowed' => 'El acceso con ese método no está habilitado.',
    'too-many-requests' =>
      'Demasiados intentos. Intenta más tarde o restablece tu contraseña.',
    'network-request-failed' => 'Sin conexión a internet.',
    _ => 'Ocurrió un error. Intenta de nuevo.',
  };
}
