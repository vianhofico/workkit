import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/features/documents/application/document_providers.dart';
import 'package:workkit/features/documents/domain/work_document.dart';
import 'package:workkit/features/pdf/application/pdf_toolkit_providers.dart';
import 'package:workkit/features/pdf/application/pdf_toolkit_service.dart';
import 'package:workkit/features/pdf/domain/page_selection_parser.dart';
import 'package:workkit/features/pdf/domain/pdf_toolkit_engine.dart';

enum _PdfOperation {
  imagesToPdf('Image to PDF'),
  merge('Merge PDFs'),
  split('Split PDF'),
  deletePages('Delete pages'),
  reorder('Reorder pages'),
  rotate('Rotate pages'),
  toImages('PDF to images');

  const _PdfOperation(this.label);
  final String label;
}

class PdfToolkitScreen extends ConsumerStatefulWidget {
  const PdfToolkitScreen({super.key});

  @override
  ConsumerState<PdfToolkitScreen> createState() => _PdfToolkitScreenState();
}

class _PdfToolkitScreenState extends ConsumerState<PdfToolkitScreen> {
  _PdfOperation _operation = _PdfOperation.merge;
  final Set<String> _selected = <String>{};
  final TextEditingController _pages = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _number = TextEditingController(text: '2');
  bool _busy = false;
  List<WorkDocument> _outputs = const <WorkDocument>[];

  @override
  void dispose() {
    _pages.dispose();
    _password.dispose();
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<WorkDocument>> asyncDocuments = ref.watch(documentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('PDF toolkit')),
      body: asyncDocuments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(child: Text('Unable to load documents.')),
        data: (documents) {
          final List<WorkDocument> candidates = _operation == _PdfOperation.imagesToPdf
              ? documents.where((item) => item.type == 'image').toList()
              : documents.where((item) => item.type == 'pdf').toList();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text('Local PDF operations', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Operations stream files from disk and write new managed copies. Original files are never overwritten.'),
              const SizedBox(height: 20),
              DropdownButtonFormField<_PdfOperation>(
                initialValue: _operation,
                decoration: const InputDecoration(labelText: 'Operation', border: OutlineInputBorder()),
                items: _PdfOperation.values
                    .map((item) => DropdownMenuItem(value: item, child: Text(item.label)))
                    .toList(),
                onChanged: _busy
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _operation = value;
                            _selected.clear();
                            _outputs = const <WorkDocument>[];
                          });
                        }
                      },
              ),
              const SizedBox(height: 16),
              Text('Choose ${_isMulti ? 'files' : 'a file'}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (candidates.isEmpty)
                const Text('No compatible files in the library yet.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: candidates.map((document) {
                    return FilterChip(
                      label: Text(document.name),
                      selected: _selected.contains(document.id),
                      onSelected: _busy
                          ? null
                          : (selected) {
                              setState(() {
                                if (!_isMulti) {
                                  _selected.clear();
                                }
                                if (selected) {
                                  _selected.add(document.id);
                                } else {
                                  _selected.remove(document.id);
                                }
                              });
                            },
                    );
                  }).toList(),
                ),
              if (_needsPages) ...<Widget>[
                const SizedBox(height: 16),
                TextField(
                  controller: _pages,
                  decoration: InputDecoration(
                    labelText: _operation == _PdfOperation.reorder
                        ? 'New page order (e.g. 3,1,2)'
                        : 'Pages (e.g. 1,3-5)',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              if (_operation == _PdfOperation.split || _operation == _PdfOperation.rotate) ...<Widget>[
                const SizedBox(height: 16),
                TextField(
                  controller: _number,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _operation == _PdfOperation.split
                        ? 'Pages per output PDF'
                        : 'Rotation degrees: 90, 180 or 270',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              if (_operation != _PdfOperation.imagesToPdf) ...<Widget>[
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'PDF password (only if protected)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy || _selected.isEmpty ? null : () => _run(documents),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run locally'),
              ),
              if (_busy) ...<Widget>[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (_outputs.isNotEmpty) ...<Widget>[
                const SizedBox(height: 24),
                Text('Saved to WorkKit', style: Theme.of(context).textTheme.titleMedium),
                ..._outputs.map((item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(item.type == 'pdf' ? Icons.picture_as_pdf : Icons.image),
                      title: Text(item.name),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  bool get _isMulti =>
      _operation == _PdfOperation.imagesToPdf || _operation == _PdfOperation.merge;

  bool get _needsPages =>
      _operation == _PdfOperation.deletePages ||
      _operation == _PdfOperation.reorder ||
      _operation == _PdfOperation.rotate;

  Future<void> _run(List<WorkDocument> all) async {
    final List<WorkDocument> selected =
        all.where((item) => _selected.contains(item.id)).toList(growable: false);
    if (selected.isEmpty) return;
    setState(() => _busy = true);
    try {
      final PdfToolkitService service = await ref.read(pdfToolkitServiceProvider.future);
      final String? password = _password.text.trim().isEmpty ? null : _password.text.trim();
      late List<WorkDocument> output;
      switch (_operation) {
        case _PdfOperation.imagesToPdf:
          output = await service.imagesToPdf(selected);
        case _PdfOperation.merge:
          output = await service.merge(selected, password: password);
        case _PdfOperation.split:
          final int every = int.tryParse(_number.text.trim()) ?? 0;
          output = await service.split(selected.first, every, password: password);
        case _PdfOperation.deletePages:
          output = await service.deletePages(
            selected.first,
            PageSelectionParser.parse(_pages.text),
            password: password,
          );
        case _PdfOperation.reorder:
          output = await service.reorderPages(
            selected.first,
            PageSelectionParser.parseOrder(_pages.text),
            password: password,
          );
        case _PdfOperation.rotate:
          final int degrees = int.tryParse(_number.text.trim()) ?? 0;
          if (!<int>{90, 180, 270}.contains(degrees)) {
            throw const FormatException('Rotation must be 90, 180 or 270 degrees.');
          }
          output = await service.rotatePages(
            selected.first,
            <int, int>{for (final int page in PageSelectionParser.parse(_pages.text)) page: degrees},
            password: password,
          );
        case _PdfOperation.toImages:
          output = await service.pdfToImages(selected.first, password: password);
      }
      if (mounted) {
        setState(() => _outputs = output);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created ${output.length} managed file(s).')),
        );
      }
    } on PdfToolkitException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF operation failed.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
