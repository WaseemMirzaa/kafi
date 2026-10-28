import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:kafi_app/services/interfaces/i_storage_service.dart';

/// Firebase Storage implementation per Technical Architecture §7.
class FirebaseStorageServiceImpl implements IStorageService {
  final _bucket = FirebaseStorage.instance.ref();

  SettableMetadata? _meta(String? contentType) =>
      contentType == null ? null : SettableMetadata(contentType: contentType);

  @override
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final ref = _bucket.child(path);
    await ref.putData(bytes, _meta(contentType));
    return ref.getDownloadURL();
  }

  @override
  Future<String> uploadFile({
    required String path,
    required File file,
    String? contentType,
  }) async {
    final ref = _bucket.child(path);
    // putFile uses a resumable upload from disk — required for intro videos
    // that can be tens of MB (putData loads everything into RAM first).
    await ref.putFile(file, _meta(contentType));
    return ref.getDownloadURL();
  }

  @override
  Future<void> deleteFile(String path) => _bucket.child(path).delete();

  @override
  Future<String?> resolveDownloadUrl(String pathOrUrl) async {
    final raw = pathOrUrl.trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    try {
      final Reference ref;
      if (raw.startsWith('gs://')) {
        ref = FirebaseStorage.instance.refFromURL(raw);
      } else {
        ref = _bucket.child(raw.startsWith('/') ? raw.substring(1) : raw);
      }
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}
