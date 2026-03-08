import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// [StorageService] centraliza la carga de archivos a Firebase Storage.
class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Sube una imagen como bytes y devuelve la URL de descarga.
  ///
  /// [bytes] contenido del archivo.
  /// [path] ruta en Storage, ej: 'products/{userId}/{filename}.jpg'.
  Future<String> uploadImage(Uint8List bytes, String path) async {
    final ref = _storage.ref(path);
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  /// Elimina un archivo de Storage por su ruta.
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (e) {
      // Ignorar si el archivo no existe
      if (e.code != 'object-not-found') rethrow;
    }
  }

  /// Obtiene la URL de descarga de un archivo en Storage.
  Future<String> getDownloadUrl(String path) async {
    return _storage.ref(path).getDownloadURL();
  }

  /// Sube un archivo y devuelve la URL. Permite especificar contentType.
  Future<String> uploadFile(
    Uint8List bytes,
    String path, {
    String contentType = 'application/octet-stream',
  }) async {
    final ref = _storage.ref(path);
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }
}
