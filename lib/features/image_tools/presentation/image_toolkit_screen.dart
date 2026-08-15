import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/features/documents/application/document_providers.dart';
import 'package:workkit/features/documents/domain/work_document.dart';
import 'package:workkit/features/image_tools/application/image_toolkit_providers.dart';
import 'package:workkit/features/image_tools/application/image_toolkit_service.dart';
import 'package:workkit/features/image_tools/domain/image_toolkit_engine.dart';

enum _ImageOperation {
  compress('Compress'),
  resize('Resize'),
  crop('Crop'),
  convert('Convert'),
  removeMetadata('Remove metadata');

  const _ImageOperation(this.label);
  final String label;
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
    final AsyncValue<List<WorkDocument>> documentsAsync = ref.watch(documentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Image toolkit')),
      body: documentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(child: Text('Unable to load images.')),
        data: _content,
      ),
    );
  }

  Widget _content(List<WorkDocument> documents) {
    final List<WorkDocument> images =
        documents.where((item) => item.type == 'image').toList(growable: false);
    final WorkDocument? selected = _find(images, _selectedId);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text('Local image operations', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Processing runs off the UI isolate and always creates a managed copy. Original images are never overwritten.',
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<_ImageOperation>(
          initialValue: _operation,
          decoration: const InputDecoration(labelText: 'Operation', border: OutlineInputBorder()),
          items: _ImageOperation.values
              .map((item) => DropdownMenuItem(value: item, child: Text(item.label)))
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
          decoration: const InputDecoration(labelText: 'Image', border: OutlineInputBorder()),
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
          const Text('Import or scan an image first.'),
        ],
        if (selected != null) ...<Widget>[
          const SizedBox(height: 16),
          _preview(selected),
        ],
        if (_operation == _ImageOperation.compress ||
            _operation == _ImageOperation.convert) ...<Widget>[
          const SizedBox(height: 16),
          TextField(
            controller: _quality,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'JPEG quality (1–100; PNG/WebP are lossless)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        if (_operation == _ImageOperation.resize) ...<Widget>[
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(child: _numberField(_width, 'Width px', allowEmpty: true)),
              const SizedBox(width: 12),
              Expanded(child: _numberField(_height, 'Height px', allowEmpty: true)),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Maintain aspect ratio'),
            subtitle: const Text('When both dimensions are set, the image fits inside that box.'),
            value: _maintainAspect,
            onChanged: _busy ? null : (value) => setState(() => _maintainAspect = value),
          ),
        ],
        if (_operation == _ImageOperation.crop) ...<Widget>[
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(child: _numberField(_x, 'X px')),
              const SizedBox(width: 12),
              Expanded(child: _numberField(_y, 'Y px')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(child: _numberField(_cropWidth, 'Crop width px')),
              const SizedBox(width: 12),
              Expanded(child: _numberField(_cropHeight, 'Crop height px')),
            ],
          ),
        ],
        if (_operation == _ImageOperation.convert) ...<Widget>[
          const SizedBox(height: 16),
          DropdownButtonFormField<ImageOutputFormat>(
            initialValue: _format,
            decoration: const InputDecoration(labelText: 'Output format', border: OutlineInputBorder()),
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
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Creates a new copy with EXIF, embedded text, and ICC profile metadata removed.',
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy || selected == null ? null : () => _run(selected),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Run locally'),
        ),
        if (_busy) ...<Widget>[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        if (_output != null) ...<Widget>[
          const SizedBox(height: 24),
          Text('Saved to WorkKit', style: Theme.of(context).textTheme.titleMedium),
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
        helperText: allowEmpty ? 'Optional' : null,
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
      final ImageToolkitService service = await ref.read(imageToolkitServiceProvider.future);
      late WorkDocument output;
      switch (_operation) {
        case _ImageOperation.compress:
          output = await service.compress(selected, quality: _int(_quality, 'Quality'));
        case _ImageOperation.resize:
          output = await service.resize(
            selected,
            width: _optionalInt(_width, 'Width'),
            height: _optionalInt(_height, 'Height'),
            maintainAspect: _maintainAspect,
          );
        case _ImageOperation.crop:
          output = await service.crop(
            selected,
            x: _int(_x, 'X', allowZero: true),
            y: _int(_y, 'Y', allowZero: true),
            width: _int(_cropWidth, 'Crop width'),
            height: _int(_cropHeight, 'Crop height'),
          );
        case _ImageOperation.convert:
          output = await service.convert(
            selected,
            _format,
            quality: _int(_quality, 'Quality'),
          );
        case _ImageOperation.removeMetadata:
          output = await service.removeMetadata(selected);
      }
      if (mounted) {
        setState(() => _output = output);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved ${output.name}.')),
        );
      }
    } on FormatException catch (error) {
      _show(error.message);
    } on ImageToolkitException catch (error) {
      _show(error.message);
    } catch (_) {
      _show('Image operation failed.');
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
      throw FormatException('$field must be ${allowZero ? '0 or greater' : 'greater than 0'}.');
    }
    return value;
  }

  int? _optionalInt(TextEditingController controller, String field) {
    final String text = controller.text.trim();
    if (text.isEmpty) return null;
    final int? value = int.tryParse(text);
    if (value == null || value <= 0) {
      throw FormatException('$field must be greater than 0.');
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
