// =============================================================================
//  Validators
//  Colección de funciones de validación reutilizables para formularios y datos
//  de entrada en toda la aplicación.
//
//  TODO: Extender con validaciones específicas para:
//    - nombres de clientes, descripciones de diseños.
//    - precios y cantidades de inventario.
//    - fechas de entrega de pedidos.
// =============================================================================

class AppValidators {
  AppValidators._(); // Clase utilitaria — no instanciar

  /// Devuelve un mensaje de error si [value] está vacío o nulo; null si es válido.
  static String? required(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }

  /// Valida formato de correo electrónico.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'El correo es obligatorio';
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]{2,}$');
    if (!re.hasMatch(value.trim())) return 'El formato del correo no es válido';
    return null;
  }

  /// Valida longitud mínima de contraseña.
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
    if (value.length < minLength) {
      return 'La contraseña debe tener al menos $minLength caracteres';
    }
    return null;
  }

  /// Valida que el valor sea un número entero positivo.
  static String? positiveInt(String? value, {String fieldName = 'El valor'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    final n = int.tryParse(value.trim());
    if (n == null || n <= 0)
      return '$fieldName debe ser un número entero positivo';
    return null;
  }
}
