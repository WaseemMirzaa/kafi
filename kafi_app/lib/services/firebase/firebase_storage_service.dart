import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:kafi_app/services/interfaces/i_storage_service.dart';

/// Firebase Storage implementation per Technical Architecture §7.
class FirebaseStorageServiceImpl implements IStorageService {
  final _bucket = FirebaseStorage.instance.ref();

  @override
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final ref = _bucket.child(path);
    await ref.putData(
      bytes,
      contentType == null ? null : SettableMetadata(contentType: contentType),
    );
    return ref.getDownloadURL();
  }

  @override
  Future<void> deleteFile(String path) => _bucket.child(path).delete();
}
