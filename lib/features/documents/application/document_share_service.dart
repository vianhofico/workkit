import 'dart:ui';

import 'package:share_plus/share_plus.dart';
import 'package:workkit/features/documents/domain/work_document.dart';

class DocumentShareService {
  const DocumentShareService();

  Future<ShareResult> share(
    WorkDocument document, {
    required Rect sharePositionOrigin,
  }) {
    return SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(document.path)],
        title: document.name,
        subject: document.name,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
