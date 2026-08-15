import 'package:file_picker/file_picker.dart';
import 'package:workkit/core/errors/app_failure.dart';
import 'package:workkit/features/documents/domain/document_picker.dart';

class FilePickerDocumentPicker implements DocumentPicker {
  const FilePickerDocumentPicker();

  @override
  Future<PickedDocument?> pick() async {
    final FilePickerResult? result = await FilePicker.pickFiles();

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final PlatformFile file = result.files.single;
    final String? path = file.path;
    if (path == null || path.trim().isEmpty) {
      throw const StorageFailure(
        'This file provider did not expose a local file path.',
      );
    }

    return PickedDocument(
      name: file.name,
      path: path,
      sizeBytes: file.size,
    );
  }
}
