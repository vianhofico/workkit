import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/core/localization/localization_extensions.dart';
import 'package:workkit/features/documents/application/document_providers.dart';
import 'package:workkit/features/documents/domain/work_document.dart';
import 'package:workkit/features/image_tools/application/image_toolkit_providers.dart';
import 'package:workkit/features/image_tools/application/image_toolkit_service.dart';
import 'package:workkit/features/image_tools/domain/image_toolkit_engine.dart';
import 'package:workkit/l10n/app_localizations.dart';

enum _ImageOperation { compress, resize, crop, convert, removeMetadata }

extension on _ImageOperation {
  String label(AppLocalizations l10n) => switch (this) {
        _ImageOperation.compress => l10n.compress,
        _ImageOperation.resize => l10n.resize,
        _ImageOperation.crop => l10n.crop,
        _ImageOperation.convert => l10n.convert,
        _ImageOperation.removeMetadata => l10n.removeMetadata,
      };
}

class ImageToolkitScreen extends ConsumerStatefulWidget {
  const ImageToolkitScreen({super.key});

  @override
  ConsumerState<ImageToolkitScreen> createState() => _ImageToolkitScreenState();
}

class _ImageToolkitScreenState extends ConsumerState<ImageToolkitScreen> {
  _ImageOperation _operation = _ImageOperation.compress;
  ImageOutputFormat _format = ImageOutputFormat.jpg;
  String? _selectedId;
  final TextEditingController _quality = TextEditingController(text: '80');
  final TextEditingController _width = TextEditingController(text: '1080');
  final TextEditingController _height = TextEditingController();
  final TextEditingController _x = TextEditingController(text: '0');
  final TextEditingController _y = TextEditingController(text: '0');
  final TextEditingController _cropWidth = TextEditingController(text: '500');
  final TextEditingController _cropHeight = TextEditingController(text: '500');
  bool _maintainAspect = true;
  bool _busy = false;
  WorkDocument? _output;

  @override
  void dispose() {
    _quality.dispose();
    _width.dispose();
    _height.dispose();
    _x.dispose();
    _y.dispose();
    _cropWidth.dispose();
    _cropHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final AsyncValue<List<WorkDocument>> documentsAsync = ref.watch(documentsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.imageToolkit)),
      body: documentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.unableLoadImages)),
        data: _content,
      ),
    );
  }

  Widget _content(List<WorkDocument> documents) {
    final l10n = context.l10n;
    final List<WorkDocument> images =
        documents.where((item) => item.type == 'image').toList(growable: false);
    final WorkDocument? selected = _find(images, _selectedId);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text(l10n.localImageOperations, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(l10n.imageDescription),
        const SizedBox(height: 20),
        DropdownButtonFormField<_ImageOperation>(
          initialValue: _operation,
          decoration: InputDecoration(labelText: l10n.operation, border: const OutlineInputBorder()),
          items: _ImageOperation.values
              .map((item) => DropdownMenuItem(value: item, child: Text(item.label(l10n))))
              .toList(),
          onChanged: _busy
              ? null
              : (value) {
                  if (value != null) {
                    setState(() {
                      _operation = value;
                      _output = null;
                    });
                  }
                },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedId,
          decoration: InputDecoration(labelText: l10n.image, border: const OutlineInputBorder()),
          items: images
              .map((item) => DropdownMenuItem<String>(value: item.id, child: Text(item.name)))
              .toList(),
          onChanged: _busy
              ? null
              : (value) => setState(() {
                    _selectedId = value;
                    _output = null;
                  }),
        ),
        if (images.isEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(l10n.importScanImageFirst),
        ],
        if (selected != null) ...<Widget>[
          const SizedBox(height: 16),
          _preview(selected),
        ],
        if (_operation == _ImageOperation.compress || _operation == _ImageOperation.convert) ...<Widget>[
          const SizedBox(height: 16),
          TextField(
            controller: _quality,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.jpegQuality,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
        if (_operation == _ImageOperation.resize) ...<Widget>[
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(child: _numberField(_width, l10n.widthPx, allowEmpty: true)),
              const SizedBox(width: 12),
              Expanded(child: _numberField(_height, l10n.heightPx, allowEmpty: true)),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.maintainAspectRatio),
            subtitle: Text(l10n.aspectRatioDescription),
            value: _maintainAspect,
            onChanged: _busy ? null : (value) => setState(() => _maintainAspect = value),
          ),
        ],
        if (_operation == _ImageOperation.crop) ...<Widget>[
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(child: _numberField(_x, l10n.xPx)),
              const SizedBox(width: 12),
              Expanded(child: _numberField(_y, l10n.yPx)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(child: _numberField(_cropWidth, l10n.cropWidthPx)),
              const SizedBox(width: 12),
              Expanded(child: _numberField(_cropHeight, l10n.cropHeightPx)),
            ],
          ),
        ],
        if (_operation == _ImageOperation.convert) ...<Widget>[
          const SizedBox(height: 16),
          DropdownButtonFormField<ImageOutputFormat>(
            initialValue: _format,
            decoration: InputDecoration(labelText: l10n.outputFormat, border: const OutlineInputBorder()),
            items: ImageOutputFormat.values
                .map(
                  (format) => DropdownMenuItem<ImageOutputFormat>(
                    value: format,
                    child: Text(format.extension.toUpperCase()),
                  ),
                )
                .toList(),
            onChanged: _busy ? null : (value) => setState(() => _format = value ?? _format),
          ),
        ],
        if (_operation == _ImageOperation.removeMetadata) ...<Widget>[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.metadataRemovalDescription),
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy || selected == null ? null : () => _run(selected),
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.runLocally),
        ),
        if (_busy) ...<Widget>[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        if (_output != null) ...<Widget>[
          const SizedBox(height: 24),
          Text(l10n.savedToWorkKit, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _preview(_output!),
        ],
      ],
    );
  }

  Widget _preview(WorkDocument document) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Image.file(
                File(document.path),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(document.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(_formatBytes(document.sizeBytes)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    bool allowEmpty = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        helperText: allowEmpty ? context.l10n.optional : null,
        border: const OutlineInputBorder(),
      ),
    );
  }

  WorkDocument? _find(List<WorkDocument> documents, String? id) {
    if (id == null) return null;
    for (final WorkDocument document in documents) {
      if (document.id == id) return document;
    }
    return null;
  }

  Future<void> _run(WorkDocument selected) async {
    setState(() => _busy = true);
    try {
      final l10n = context.l10n;
      final ImageToolkitService service = await ref.read(imageToolkitServiceProvider.future);
      late WorkDocument output;
      switch (_operation) {
        case _ImageOperation.compress:
          output = await service.compress(selected, quality: _int(_quality, l10n.quality));
        case _ImageOperation.resize:
          output = await service.resize(
            selected,
            width: _optionalInt(_width, l10n.width),
            height: _optionalInt(_height, l10n.height),
            maintainAspect: _maintainAspect,
          );
        case _ImageOperation.crop:
          output = await service.crop(
            selected,
            x: _int(_x, 'X', allowZero: true),
            y: _int(_y, 'Y', allowZero: true),
            width: _int(_cropWidth, l10n.cropWidth),
            height: _int(_cropHeight, l10n.cropHeight),
          );
        case _ImageOperation.convert:
          output = await service.convert(
            selected,
            _format,
            quality: _int(_quality, l10n.quality),
          );
        case _ImageOperation.removeMetadata:
          output = await service.removeMetadata(selected);
      }
      if (mounted) {
        setState(() => _output = output);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.savedNamed(output.name))),
        );
      }
    } on FormatException catch (error) {
      _show(error.message);
    } on ImageToolkitException catch (_) {
      _show(context.l10n.imageOperationFailed);
    } catch (_) {
      _show(context.l10n.imageOperationFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int _int(
    TextEditingController controller,
    String field, {
    bool allowZero = false,
  }) {
    final int? value = int.tryParse(controller.text.trim());
    final bool valid = value != null && (allowZero ? value >= 0 : value > 0);
    if (!valid) {
      throw FormatException(
        allowZero
            ? context.l10n.mustBeZeroOrGreater(field)
            : context.l10n.mustBeGreaterThanZero(field),
      );
    }
    return value;
  }

  int? _optionalInt(TextEditingController controller, String field) {
    final String text = controller.text.trim();
    if (text.isEmpty) return null;
    final int? value = int.tryParse(text);
    if (value == null || value <= 0) {
      throw FormatException(context.l10n.mustBeGreaterThanZero(field));
    }
    return value;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
