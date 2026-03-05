// =============================================================================
//  AuthService
//  Capa de servicio de autenticación para operaciones que combinan
//  FirebaseAuth con la base de datos (p. ej., crear el perfil de usuario
//  en Firestore al registrarse).
//
//  Estado: PENDIENTE DE IMPLEMENTACIÓN.
//  La autenticación básica (signIn / signOut / reset) ya está cubierta
//  por [AuthRepository]. Este servicio ampliará esa funcionalidad.
// =============================================================================

/// [AuthService] orquesta operaciones de auth que tocan más de una fuente
/// de datos (FirebaseAuth + Firestore 'users' collection).
class AuthService {
  // TODO: Implementar createUserProfile(User user) para crear el
  //       documento en 'users/{uid}' al completar el registro.

  // TODO: Implementar updateDisplayName(String name).

  // TODO: Implementar deleteAccount() con cleanup de Firestore.
}
