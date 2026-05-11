// Stub para web - no usamos SQLite en web, solo Firestore
class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Future<void> get database async {
    // No-op en web
  }
}
