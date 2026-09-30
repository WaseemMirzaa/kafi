import 'dart:io';
import 'dart:typed_data';

import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/services/interfaces/i_storage_service.dart';
import 'package:path_provider/path_provider.dart';

class MockStorageService implements IStorageService {
  @override
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    await Future<void>.delayed(AppConfig.mockDelay);

    // Persist real bytes to a temp file so Image.file / VideoPlayer can preview
    // them. Data-URIs break Image.network and video_player on device/simulator.
    if (bytes.length > 1) {
      final dir = await getTemporaryDirectory();
      final safe = path.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final file = File('${dir.path}/$safe');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }

    return 'https://mock.kafi/storage/$path';
  }

  @override
  Future<void> deleteFile(String path) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<String?> resolveDownloadUrl(String pathOrUrl) async {
    final raw = pathOrUrl.trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') ||
        raw.startsWith('https://') ||
        raw.startsWith('/')) {
      return raw;
    }
    final file = File(raw);
    if (await file.exists()) return raw;
    return 'https://mock.kafi/storage/$raw';
  }
}
