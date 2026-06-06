import 'dart:typed_data';

abstract class IStorageService {
  /// Returns a downloadable URL for the uploaded file.
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
  });

  Future<void> deleteFile(String path);
}
