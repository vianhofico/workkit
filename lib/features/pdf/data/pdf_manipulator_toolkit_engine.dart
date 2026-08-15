import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf_manipulator/io.dart' as pdf_io;
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:workkit/features/pdf/domain/pdf_toolkit_engine.dart';

class PdfManipulatorToolkitEngine implements PdfToolkitEngine {
  const PdfManipulatorToolkitEngine();

  @override
  Future<PdfToolkitOutput> imagesToPdf(List<String> imagePaths) => _guard(() async {
        if (imagePaths.isEmpty) {
          throw const PdfToolkitException('Choose at least one image.');
        }
        final Directory directory = await _temp('images-to-pdf');
        final String outputPath = '${directory.path}/images.pdf';
        final Pdf pdf = Pdf();
        final pdf_io.FileSink sink = await pdf_io.FileSink.create(File(outputPath));
        try {
          await pdf.imagesToPdf(
            imagePaths.map((path) => pdf_io.FileSource(File(path))).toList(),
            sink,
          );
          return PdfToolkitOutput(paths: <String>[outputPath], tempDirectory: directory.path);
        } finally {
          await sink.close();
          await pdf.dispose();
        }
      });

  @override
  Future<PdfToolkitOutput> merge(List<String> pdfPaths, {String? password}) => _guard(() async {
        if (pdfPaths.length < 2) {
          throw const PdfToolkitException('Choose at least two PDFs to merge.');
        }
        final Directory directory = await _temp('merge');
        final Pdf pdf = Pdf();
        final List<String> prepared = <String>[];
        try {
          for (final String path in pdfPaths) {
            prepared.add(await _preparePdf(pdf, path, password, directory));
          }
          final String outputPath = '${directory.path}/merged.pdf';
          final pdf_io.FileSink sink = await pdf_io.FileSink.create(File(outputPath));
          try {
            await pdf.merge(
              prepared.map((path) => pdf_io.FileSource(File(path))).toList(),
              sink,
            );
          } finally {
            await sink.close();
          }
          return PdfToolkitOutput(paths: <String>[outputPath], tempDirectory: directory.path);
        } finally {
          await pdf.dispose();
        }
      });

  @override
  Future<PdfToolkitOutput> split(String pdfPath, int every, {String? password}) => _guard(() async {
        if (every < 1) {
          throw const PdfToolkitException('Split size must be at least one page.');
        }
        final Directory directory = await _temp('split');
        final Pdf pdf = Pdf();
        final List<_SyncDataSink> sinks = <_SyncDataSink>[];
        final List<String> paths = <String>[];
        try {
          final String prepared = await _preparePdf(pdf, pdfPath, password, directory);
          await pdf.split(
            pdf_io.FileSource(File(prepared)),
            (int index) {
              final String path = '${directory.path}/part-${index + 1}.pdf';
              final _SyncDataSink sink = _SyncDataSink(File(path));
              sinks.add(sink);
              paths.add(path);
              return sink;
            },
            every: every,
          );
          return PdfToolkitOutput(paths: paths, tempDirectory: directory.path);
        } finally {
          for (final _SyncDataSink sink in sinks) {
            sink.close();
          }
          await pdf.dispose();
        }
      });

  @override
  Future<PdfToolkitOutput> deletePages(
    String pdfPath,
    List<int> pages, {
    String? password,
  }) => _singleOutput(
        'delete-pages',
        pdfPath,
        password,
        (Pdf pdf, DataSource source, DataSink sink) =>
            pdf.deletePages(source, sink, pages: pages),
      );

  @override
  Future<PdfToolkitOutput> reorderPages(
    String pdfPath,
    List<int> order, {
    String? password,
  }) => _singleOutput(
        'reorder-pages',
        pdfPath,
        password,
        (Pdf pdf, DataSource source, DataSink sink) =>
            pdf.reorderPages(source, sink, order: order),
      );

  @override
  Future<PdfToolkitOutput> rotatePages(
    String pdfPath,
    Map<int, int> pages, {
    String? password,
  }) => _singleOutput(
        'rotate-pages',
        pdfPath,
        password,
        (Pdf pdf, DataSource source, DataSink sink) =>
            pdf.rotatePages(source, sink, pages: pages),
      );

  @override
  Future<PdfToolkitOutput> pdfToImages(String pdfPath, {String? password}) => _guard(() async {
        final Directory directory = await _temp('pdf-images');
        final Pdf pdf = Pdf();
        PdfDoc? document;
        final List<String> paths = <String>[];
        try {
          final String prepared = await _preparePdf(pdf, pdfPath, password, directory);
          document = await pdf.open(pdf_io.FileSource(File(prepared)));
          int index = 0;
          await for (final RenderedPage page in document.render(
            pages: const PdfPages.all(),
            size: const PdfRenderSize(maxWidth: 2400, maxHeight: 3200),
          )) {
            final String path = '${directory.path}/page-${index + 1}.png';
            await File(path).writeAsBytes(page.data, flush: true);
            paths.add(path);
            index++;
          }
          if (paths.isEmpty) {
            throw const PdfToolkitException('The PDF contains no renderable pages.');
          }
          return PdfToolkitOutput(paths: paths, tempDirectory: directory.path);
        } finally {
          await document?.dispose();
          await pdf.dispose();
        }
      });

  @override
  Future<int> pageCount(String pdfPath, {String? password}) => _guard(() async {
        final Pdf pdf = Pdf();
        PdfDoc? document;
        try {
          document = await pdf.open(
            pdf_io.FileSource(File(pdfPath)),
            password: _password(password),
          );
          return document.pageCount;
        } finally {
          await document?.dispose();
          await pdf.dispose();
        }
      });

  Future<PdfToolkitOutput> _singleOutput(
    String prefix,
    String pdfPath,
    String? password,
    Future<void> Function(Pdf pdf, DataSource source, DataSink sink) operation,
  ) => _guard(() async {
        final Directory directory = await _temp(prefix);
        final Pdf pdf = Pdf();
        try {
          final String prepared = await _preparePdf(pdf, pdfPath, password, directory);
          final String outputPath = '${directory.path}/$prefix.pdf';
          final pdf_io.FileSink sink = await pdf_io.FileSink.create(File(outputPath));
          try {
            await operation(pdf, pdf_io.FileSource(File(prepared)), sink);
          } finally {
            await sink.close();
          }
          return PdfToolkitOutput(paths: <String>[outputPath], tempDirectory: directory.path);
        } finally {
          await pdf.dispose();
        }
      });

  Future<String> _preparePdf(
    Pdf pdf,
    String path,
    String? password,
    Directory directory,
  ) async {
    final pdf_io.FileSource source = pdf_io.FileSource(File(path));
    PdfDoc? document;
    try {
      document = await pdf.open(source, password: _password(password));
      if (!document.isEncrypted) {
        return path;
      }
    } finally {
      await document?.dispose();
    }

    final String? normalizedPassword = _password(password);
    if (normalizedPassword == null) {
      throw const PdfToolkitException(
        'This PDF is password protected. Enter its password and try again.',
        passwordRequired: true,
      );
    }
    final String decrypted = '${directory.path}/decrypted-${DateTime.now().microsecondsSinceEpoch}.pdf';
    final pdf_io.FileSink sink = await pdf_io.FileSink.create(File(decrypted));
    try {
      await pdf.decrypt(source, sink, password: normalizedPassword);
    } finally {
      await sink.close();
    }
    return decrypted;
  }

  String? _password(String? value) {
    final String normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  Future<Directory> _temp(String prefix) =>
      Directory.systemTemp.createTemp('workkit_pdf_${prefix}_');

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PdfPasswordRequired {
      throw const PdfToolkitException(
        'This PDF is password protected. Enter its password and try again.',
        passwordRequired: true,
      );
    } on PdfWrongPassword {
      throw const PdfToolkitException('The PDF password is incorrect.', passwordRequired: true);
    } on PdfError catch (error) {
      throw PdfToolkitException(error.message);
    }
  }

  @override
  Future<void> cleanup(PdfToolkitOutput output) async {
    final Directory directory = Directory(output.tempDirectory);
    if (await directory.exists() && directory.path.contains('workkit_pdf_')) {
      await directory.delete(recursive: true);
    }
  }
}

class _SyncDataSink implements DataSink {
  _SyncDataSink(File file) : _file = file.openSync(mode: FileMode.write);

  final RandomAccessFile _file;

  @override
  void write(Uint8List chunk) => _file.writeFromSync(chunk);

  void close() => _file.closeSync();
}
