import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Servicio de almacenamiento con Firebase Storage.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Subir una imagen y retornar la URL de descarga.
  Future<String> uploadImage({
    required String path,
    required Uint8List data,
    String contentType = 'image/jpeg',
  }) async {
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(data, metadata);
    return await ref.getDownloadURL();
  }

  /// Eliminar un archivo por su path en Storage.
  Future<void> deleteFile(String path) async {
    await _storage.ref().child(path).delete();
  }

  /// Obtener la URL de descarga de un archivo.
  Future<String> getDownloadUrl(String path) async {
    return await _storage.ref().child(path).getDownloadURL();
  }
}
