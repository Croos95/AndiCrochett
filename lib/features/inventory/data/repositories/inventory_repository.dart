// =============================================================================
//  InventoryRepository
//  Acceso a Firestore para la colección 'products'.
//
//  Operaciones planificadas:
//    watchByUser(userId)  → Stream<List<ProductModel>> ordenado por nombre.
//    watchLowStock(uid)   → Stream de productos con status == 'low_stock'.
//    create(ProductModel) → Future<String>.
//    update(ProductModel) → Future<void>.
//    delete(String id)    → Future<void>.
//    updateStock(id, qty) → Incremento/decremento atómico con FieldValue.
//
//  Estado: PENDIENTE DE IMPLEMENTACIÓN.
//  La UI de inventario actualmente usa datos estáticos mock.
// =============================================================================
