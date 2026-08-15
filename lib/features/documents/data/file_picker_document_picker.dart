import 'package:file_selector/file_selector.dart';
import 'package:workkit/core/errors/app_failure.dart';
import 'package:workkit/features/documents/domain/document_picker.dart';

class FilePickerDocumentPicker implements DocumentPicker {
  const FilePickerDocumentPicker();

  @override
  Future<PickedDocument?> pick() async {
    final XFile? file = await openFile();
    if (file == null) {
      return null;
    }

    final String path = file.path.trim();
    if (path.isEmpty) {
      throw const StorageFailure(
        'This file provider did not expose a local file path.',
      );
    }

    return PickedDocument(
      name: file.name,
      path: path,
      sizeBytes: await file.length(),
    );
  }
}
