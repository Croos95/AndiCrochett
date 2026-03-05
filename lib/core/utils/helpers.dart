// =============================================================================
//  Helpers
//  Funciones utilitarias de propósito general usadas en múltiples capas
//  de la aplicación.
//
//  TODO: Agregar helpers para:
//    - formateo de fechas (pedidos, diseños).
//    - formateo de moneda (precios de inventario).
//    - truncado de texto largo para tarjetas.
//
//  NOTA: Si se agrega el paquete 'intl' al proyecto, reemplazar los métodos
//  de fecha por DateFormat('dd/MM/yyyy', 'es').format(date) para soporte
//  completo de localización.
// =============================================================================

class AppHelpers {
  AppHelpers._(); // Clase utilitaria — no instanciar

  /// Formatea [date] al patrón 'dd/MM/yyyy'.
  /// Si [date] es nulo devuelve una cadena vacía.
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  /// Formatea [date] con hora: 'dd/MM/yyyy – HH:mm'.
  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$d/$m/${date.year} – $hh:$mm';
  }

  /// Devuelve una representación relativa de [date] (Hoy, Ayer, 'hace N días').
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return 'Hace $diff días';
    return formatDate(date);
  }

  /// Trunca [text] a [maxLength] caracteres y añade '…' si es más largo.
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}…';
  }
}
