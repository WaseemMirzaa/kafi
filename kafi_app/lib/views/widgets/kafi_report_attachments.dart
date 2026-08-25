import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kafi_app/controllers/permission_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/utils/constants/dispute_constants.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

/// Local file staged on a report sheet before upload on submit.
class PendingReportAttachment {
  PendingReportAttachment({
    required this.bytes,
    required this.name,
    required this.contentType,
    required this.ext,
  });

  final Uint8List bytes;
  final String name;
  final String contentType;
  final String ext;

  bool get isImage => contentType.toLowerCase().startsWith('image/');
}

/// Shared attachment strip for report sheets: add photo/PDF, preview, remove.
class KafiReportAttachments extends StatelessWidget {
  const KafiReportAttachments({
    super.key,
    required this.files,
    required this.onChanged,
  });

  final List<PendingReportAttachment> files;
  final ValueChanged<List<PendingReportAttachment>> onChanged;

  Future<void> _addFiles(BuildContext context) async {
    if (files.length >= DisputeConstants.maxAttachments) {
      Get.snackbar(
        AppStrings.errorTitle.tr,
        AppStrings.reportAttachMax.trParams({
          'max': '${DisputeConstants.maxAttachments}',
        }),
      );
      return;
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: KafiColors.pur),
              title: Text(AppStrings.reportAttachGallery.tr,
                  style: KafiTheme.nunito(12, color: KafiColors.td, w: FontWeight.w700)),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: KafiColors.pur),
              title: Text(AppStrings.reportAttachCamera.tr,
                  style: KafiTheme.nunito(12, color: KafiColors.td, w: FontWeight.w700)),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: KafiColors.pur),
              title: Text(AppStrings.reportAttachFile.tr,
                  style: KafiTheme.nunito(12, color: KafiColors.td, w: FontWeight.w700)),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return;

    if (choice == 'gallery' || choice == 'camera') {
      final permissions = Get.find<PermissionController>();
      final ok = choice == 'camera'
          ? await permissions.requestCamera()
          : await permissions.ensureGallery();
      if (!ok) {
        Get.snackbar(
          AppStrings.errorTitle.tr,
          choice == 'camera'
              ? AppStrings.permissionCameraDenied.tr
              : AppStrings.permissionGalleryDenied.tr,
        );
        return;
      }
      final picked = await ImagePicker().pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      _append(bytes, picked.name, 'jpg');
      return;
    }

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          ...DisputeConstants.allowedImageExtensions,
          DisputeConstants.allowedPdfExtension,
        ],
        withData: true,
        allowMultiple: true,
      );
    } catch (_) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.reportAttachPickFailed.tr);
      return;
    }
    if (result == null || result.files.isEmpty) return;
    var next = List<PendingReportAttachment>.from(files);
    for (final file in result.files) {
      if (next.length >= DisputeConstants.maxAttachments) {
        Get.snackbar(
          AppStrings.errorTitle.tr,
          AppStrings.reportAttachMax.trParams({
            'max': '${DisputeConstants.maxAttachments}',
          }),
        );
        break;
      }
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        try {
          bytes = await XFile(file.path!).readAsBytes();
        } catch (_) {}
      }
      if (bytes == null) continue;
      final ext = (file.extension ?? '').toLowerCase();
      final added = _tryBuild(bytes, file.name, ext);
      if (added != null) next.add(added);
    }
    if (next.length != files.length) onChanged(next);
  }

  PendingReportAttachment? _tryBuild(Uint8List bytes, String name, String ext) {
    if (!DisputeConstants.isAllowedExtension(ext)) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.reportAttachType.tr);
      return null;
    }
    if (bytes.length > DisputeConstants.maxAttachmentBytes) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.reportAttachTooLarge.tr);
      return null;
    }
    return PendingReportAttachment(
      bytes: bytes,
      name: name.isNotEmpty ? name : 'file.$ext',
      contentType: DisputeConstants.contentTypeForExtension(ext),
      ext: ext,
    );
  }

  void _append(Uint8List bytes, String name, String ext) {
    if (files.length >= DisputeConstants.maxAttachments) {
      Get.snackbar(
        AppStrings.errorTitle.tr,
        AppStrings.reportAttachMax.trParams({
          'max': '${DisputeConstants.maxAttachments}',
        }),
      );
      return;
    }
    final built = _tryBuild(bytes, name, ext);
    if (built == null) return;
    onChanged([...files, built]);
  }

  void _remove(int index) {
    final next = List<PendingReportAttachment>.from(files)..removeAt(index);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.reportAttachLabel.tr,
            style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(AppStrings.reportAttachHint.tr,
            style: KafiTheme.nunito(9.5, color: KafiColors.ts, w: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...List.generate(files.length, (i) {
              final f = files[i];
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: KafiColors.inputBgP,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: KafiColors.purB, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: f.isImage
                        ? Image.memory(f.bytes, fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.picture_as_pdf, color: KafiColors.pur, size: 22),
                              Text(
                                f.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: KafiTheme.nunito(7, color: KafiColors.tm),
                              ),
                            ],
                          ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => _remove(i),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: KafiColors.rose,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }),
            if (files.length < DisputeConstants.maxAttachments)
              GestureDetector(
                onTap: () => _addFiles(context),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: KafiColors.inputBgP,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: KafiColors.purB, width: 1.5),
                  ),
                  child: const Icon(Icons.add, color: KafiColors.pur, size: 26),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
