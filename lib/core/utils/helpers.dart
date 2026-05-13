class AppHelpers {
  AppHelpers._();

  /// Formatea [date] al patrón 'dd/MM/yyyy'.
  /// Si [date] es nulo devuelve una cadena vacía.
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  /// Devuelve el mes abreviado + año, ej: 'ene 2025'.
  static String formatShortDate(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
