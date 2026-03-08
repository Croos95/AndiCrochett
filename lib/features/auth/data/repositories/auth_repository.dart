import 'package:andicrochett/core/services/auth_service.dart';
import 'package:andicrochett/features/auth/data/models/user_model.dart';

/// Repositorio de autenticación  capa intermedia entre UI y AuthService.
class AuthRepository {
  final AuthService _authService = AuthService();

  /// Stream de estado de autenticación.
  Stream<dynamic> get authStateChanges => _authService.authStateChanges;

  /// ¿Está autenticado?
  bool get isAuthenticated => _authService.currentUser != null;

  /// UID del usuario actual.
  String? get uid => _authService.uid;

  /// Registrar con email y contraseña.
  Future<UserModel> signUp({
    required String email,
    required String password,
    String displayName = '',
  }) {
    return _authService.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  /// Iniciar sesión con email y contraseña.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) {
    return _authService.signInWithEmail(
      email: email,
      password: password,
    );
  }

  /// Cerrar sesión.
  Future<void> signOut() => _authService.signOut();

  /// Enviar email de recuperación.
  Future<void> sendPasswordReset(String email) =>
      _authService.sendPasswordReset(email);

  /// Obtener perfil del usuario actual.
  Future<UserModel?> getCurrentUser() => _authService.getCurrentUserModel();

  /// Actualizar perfil.
  Future<void> updateProfile(UserModel user) =>
      _authService.updateUserProfile(user);
}
