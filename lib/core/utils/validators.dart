class AppValidators {
  AppValidators._();

  /// Devuelve un mensaje de error si [value] está vacío o nulo; null si es válido.
  static String? required(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }

  /// Valida que el valor sea un número entero positivo (> 0).
  static String? positiveInt(String? value, {String fieldName = 'El valor'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    final n = int.tryParse(value.trim());
    if (n == null || n <= 0) {
      return '$fieldName debe ser un número entero mayor a cero';
    }
    return null;
  }

  /// Valida que el valor sea un número entero no negativo (>= 0).
  static String? nonNegativeInt(
    String? value, {
    String fieldName = 'El valor',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    final n = int.tryParse(value.trim());
    if (n == null || n < 0) {
      return '$fieldName debe ser un número entero (≥ 0)';
    }
    return null;
  }

  /// Valida formato de color hexadecimal (opcional: vacío es válido).
  /// Acepta #RGB y #RRGGBB con o sin numeral.
  static String? optionalHexColor(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim();
    final re = RegExp(r'^#?([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$');
    if (!re.hasMatch(v)) return 'Formato inválido. Usa #RRGGBB (ej: #F48FB1)';
    return null;
  }
}
