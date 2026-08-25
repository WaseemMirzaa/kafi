/// Limits for in-app report (`disputes`) evidence uploads.
class DisputeConstants {
  DisputeConstants._();

  static const maxAttachments = 5;
  static const maxAttachmentBytes = 10 * 1024 * 1024; // 10 MB

  static const allowedImageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
    'gif',
  };

  static const allowedPdfExtension = 'pdf';

  static bool isAllowedExtension(String ext) {
    final e = ext.toLowerCase().replaceAll('.', '');
    return allowedImageExtensions.contains(e) || e == allowedPdfExtension;
  }

  static String contentTypeForExtension(String ext) {
    final e = ext.toLowerCase().replaceAll('.', '');
    return switch (e) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }

  static bool isAllowedContentType(String contentType) {
    final c = contentType.toLowerCase();
    return c.startsWith('image/') || c == 'application/pdf';
  }
}
