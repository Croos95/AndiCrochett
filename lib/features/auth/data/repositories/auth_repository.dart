import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AuthRepository
//  Wraps FirebaseAuth with typed results.
// ─────────────────────────────────────────────────────────────────────────────

class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  // ── Stream ────────────────────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Sign in with email + password ─────────────────────────────────────────

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  // ── Register with email + password ────────────────────────────────────────

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) => _auth.createUserWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );

  // ── Sign out ───────────────────────────────────────────────────────────────

  Future<void> signOut() => _auth.signOut();

  // ── Password reset ────────────────────────────────────────────────────────

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // ── Human-readable error messages ─────────────────────────────────────────

  static String messageFromCode(String code) => switch (code) {
    'user-not-found' => 'No existe una cuenta con ese correo.',
    'wrong-password' => 'Contraseña incorrecta.',
    'invalid-credential' => 'Correo o contraseña incorrectos.',
    'email-already-in-use' => 'Ese correo ya está registrado.',
    'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
    'invalid-email' => 'El formato del correo no es válido.',
    'too-many-requests' =>
      'Demasiados intentos. Intenta más tarde o restablece tu contraseña.',
    'network-request-failed' => 'Sin conexión a internet.',
    _ => 'Ocurrió un error. Intenta de nuevo.',
  };
}
