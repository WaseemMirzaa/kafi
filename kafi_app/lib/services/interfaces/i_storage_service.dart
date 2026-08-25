import 'dart:typed_data';

abstract class IStorageService {
  /// Returns a downloadable URL for the uploaded file.
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
  });

  Future<void> deleteFile(String path);

  /// Turns a Storage path or `gs://` URI into an HTTPS download URL.
  /// HTTP(S) URLs are returned unchanged. Returns null when unresolvable.
  Future<String?> resolveDownloadUrl(String pathOrUrl);
}
