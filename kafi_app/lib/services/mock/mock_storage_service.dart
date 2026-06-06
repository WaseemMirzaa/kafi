import 'dart:convert';
import 'dart:typed_data';

import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/services/interfaces/i_storage_service.dart';

class MockStorageService implements IStorageService {
  @override
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    await Future<void>.delayed(AppConfig.mockDelay);

    // Return a real data URI so uploaded images/files actually render in the UI.
    // Only encode non-trivial payloads (dummy 1-byte calls stay as mock URLs).
    if (bytes.length > 1) {
      final mime = _resolveMime(contentType, path);
      final b64 = base64Encode(bytes);
      return 'data:$mime;base64,$b64';
    }

    return 'https://mock.kafi/storage/$path';
  }

  @override
  Future<void> deleteFile(String path) async {
    await Future<void>.delayed(AppConfig.mockDelay);
  }

  String _resolveMime(String? contentType, String path) {
    if (contentType != null && contentType.isNotEmpty) return contentType;
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'mp4':
        return 'video/mp4';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
