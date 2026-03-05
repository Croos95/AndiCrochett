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
  bool get isAuthenticated => _user != null;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Auth state listener ───────────────────────────────────────────────────

  void _onAuthStateChanged(User? user) {
    _user = user;
    _status = user != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Sign in ───────────────────────────────────────────────────────────────

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading();
    try {
      await _repo.signInWithEmail(email: email, password: password);
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
      await _repo.registerWithEmail(email: email, password: password);
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

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _repo.signOut();
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
