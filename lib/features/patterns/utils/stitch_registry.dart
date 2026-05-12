// lib/features/patterns/utils/stitch_registry.dart

/// Define el comportamiento matemático de un punto de crochet.
class StitchDefinition {
  /// Puntos de la vuelta anterior que este punto necesita (ej. un aumento usa 1)
  final int consumed;
  
  /// Puntos nuevos que este punto crea para la siguiente vuelta (ej. un aumento crea 2)
  final int produced;

  const StitchDefinition(this.consumed, this.produced);
}

/// Registro global de puntos de crochet y su comportamiento.
class StitchRegistry {
  // Mapa de abreviaciones comunes a su definición matemática.
  // He incluido tanto abreviaciones en inglés (usadas mundialmente) como en español.
  static const Map<String, StitchDefinition> stitches = {
    // Básicos
    'ch': StitchDefinition(0, 1),   // Cadena / Chain (no consume de la vuelta anterior)
    'sc': StitchDefinition(1, 1),   // Punto bajo / Single crochet
    'pb': StitchDefinition(1, 1),   // Punto bajo (ES)
    
    // Modificadores de cantidad
    'inc': StitchDefinition(1, 2),  // Aumento / Increase (consume 1, crea 2)
    'aum': StitchDefinition(1, 2),  // Aumento (ES)
    'dec': StitchDefinition(2, 1),  // Disminución / Decrease (consume 2, deja 1)
    'dism': StitchDefinition(2, 1), // Disminución (ES)
    
    // Puntos altos
    'hdc': StitchDefinition(1, 1),  // Medio punto alto / Half double crochet
    'mpa': StitchDefinition(1, 1),  // Medio punto alto (ES)
    'dc': StitchDefinition(1, 1),   // Punto alto / Double crochet
    'pa': StitchDefinition(1, 1),   // Punto alto (ES)
    'tr': StitchDefinition(1, 1),   // Punto alto doble / Treble crochet
    'pad': StitchDefinition(1, 1),  // Punto alto doble (ES)
    
    // Otros
    'slst': StitchDefinition(1, 1), // Punto raso o deslizado / Slip stitch
    'pr': StitchDefinition(1, 1),   // Punto raso (ES)
    'pd': StitchDefinition(1, 1),   // Punto deslizado (ES)
  };
}
/// Define un error lógico o de sintaxis en el patrón de crochet.
class PatternError {
  final String message;
  final int rowIndex; // Para saber en qué vuelta ocurrió el error

  const PatternError(this.message, {this.rowIndex = -1});
  
  @override
  String toString() => message;
}