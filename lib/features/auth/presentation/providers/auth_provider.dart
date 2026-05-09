import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:andicrochett/features/auth/data/repositories/auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AuthProvider
// ─────────────────────────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
    : _repo = repository ?? AuthRepository() {
    _repo.authStateChanges.listen(_onAuthStateChanged);
  }

  final AuthRepository _repo;

  AuthStatus _status = AuthStatus.initial;
  AuthStatus get status => _status;

  User? _user;
  User? get user => _user;
  bool get isAuthenticated => _user != null && _user!.emailVerified;
  bool get hasVerifiedEmail => _user?.emailVerified ?? false;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Auth state listener ───────────────────────────────────────────────────

  void _onAuthStateChanged(User? user) {
    _user = user;
    _status = user != null && user.emailVerified
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Sign in ───────────────────────────────────────────────────────────────

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading();
    try {
      await _repo.signInWithEmail(email: email, password: password);
      final verified = await _repo.isEmailVerified();
      if (!verified) {
        await _repo.sendVerificationEmail();
        _setError(
          'Debes verificar tu correo antes de ingresar. Te reenviamos el enlace.',
        );
        return false;
      }
      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthRepository.messageFromCode(e.code));
      return false;
    } catch (_) {
      _setError('Ocurrió un error inesperado.');
      return false;
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      // 1. Crear la cuenta en Firebase
      await _repo.registerWithEmail(email: email, password: password);

      // 2. Enviar email de verificación
      try {
        await _repo.sendVerificationEmail();
      } on FirebaseAuthException catch (e) {
        // Si falla el envío, aún así registramos al usuario pero mostramos un error
        _setError(
          'Cuenta creada, pero no pudimos enviar el correo: ${e.message}. Intenta reenviar desde la siguiente pantalla.',
        );
        return false;
      }

      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthRepository.messageFromCode(e.code));
      return false;
    } catch (e) {
      _setError('Ocurrió un error inesperado: $e');
      return false;
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _repo.signOut();
  }

  Future<bool> signInWithGoogle() async {
    _setLoading();
    try {
      await _repo.signInWithGoogle();
      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthRepository.messageFromCode(e.code));
      return false;
    } catch (_) {
      _setError('Ocurrió un error inesperado.');
      return false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    try {
      await _repo.sendVerificationEmail();
      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(
        'No se pudo reenviar el correo: ${e.message ?? e.code}. Verifica tu conexión.',
      );
      return false;
    } catch (e) {
      _setError('Error al reenviar el correo: $e');
      return false;
    }
  }

  Future<bool> refreshVerificationStatus() async {
    final verified = await _repo.isEmailVerified();
    if (verified) {
      _onAuthStateChanged(_repo.currentUser);
    }
    return verified;
  }

  // ── Password reset ────────────────────────────────────────────────────────

  Future<bool> sendPasswordReset(String email) async {
    _setLoading();
    try {
      await _repo.sendPasswordReset(email);
      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthRepository.messageFromCode(e.code));
      return false;
    } catch (_) {
      _setError('No se pudo enviar el correo.');
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = AuthStatus.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _errorMessage = null;
    _status = _user != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    notifyListeners();
  }
}
