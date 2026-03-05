// =============================================================================
//  AgendaRepository
//  Acceso a Firestore para la colección 'orders'.
//
//  Operaciones planificadas:
//    watchByUser(userId)           → Stream de pedidos del usuario ordenados por dueDate.
//    watchByStatus(userId, status) → Stream filtrado por estado.
//    create(OrderModel order)      → Future<String> (nuevo ID).
//    update(OrderModel order)      → Future<void>.
//    delete(String id)             → Future<void>.
//    completeOrder(String id)      → Cambia status a 'completed' y actualiza stock.
//
//  Estado: PENDIENTE DE IMPLEMENTACIÓN.
// =============================================================================
