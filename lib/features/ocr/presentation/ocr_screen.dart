import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/core/errors/app_failure.dart';
import 'package:workkit/core/localization/localization_extensions.dart';
import 'package:workkit/features/documents/application/document_providers.dart';
import 'package:workkit/features/documents/domain/work_document.dart';
import 'package:workkit/features/ocr/application/ocr_providers.dart';
import 'package:workkit/features/ocr/application/ocr_service.dart';
import 'package:workkit/features/ocr/domain/smart_extractor.dart';

class OcrScreen extends ConsumerStatefulWidget {
  const OcrScreen({super.key});

  @override
  ConsumerState<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends ConsumerState<OcrScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedId;
  bool _busy = false;
  SmartEntities _entities = const SmartEntities();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final AsyncValue<List<WorkDocument>> documents = ref.watch(documentsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ocr)),
      body: documents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(l10n.unableLoadLibrary)),
        data: (items) {
          final List<WorkDocument> supported = items
              .where((document) => document.type == 'image' || document.type == 'pdf')
              .toList(growable: false);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text(l10n.onDeviceTextRecognition, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(l10n.ocrDescription),
              const SizedBox(height: 20),
              if (supported.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.importImagePdfFirst),
                  ),
                )
              else ...<Widget>[
                Text(l10n.documentSection, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: supported.map((document) {
                    return ChoiceChip(
                      label: Text(document.name, overflow: TextOverflow.ellipsis),
                      selected: _selectedId == document.id,
                      onSelected: _busy
                          ? null
                          : (selected) => _selectDocument(selected ? document : null),
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _selectedId == null || _busy ? null : () => _extract(supported),
                  icon: const Icon(Icons.text_snippet_outlined),
                  label: Text(l10n.extractText),
                ),
              ],
              if (_busy) ...<Widget>[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
              if (_controller.text.isNotEmpty || _selectedId != null) ...<Widget>[
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  minLines: 10,
                  maxLines: 20,
                  decoration: InputDecoration(
                    labelText: l10n.extractedText,
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _selectedId == null || _busy ? null : _saveEdited,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(l10n.saveEditedText),
                ),
                const SizedBox(height: 20),
                _EntitySection(entities: _entities),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectDocument(WorkDocument? document) async {
    setState(() {
      _selectedId = document?.id;
      _controller.clear();
      _entities = const SmartEntities();
    });
    if (document == null) return;
    final OcrDocumentResult? saved = await ref.read(ocrServiceProvider).load(document.id);
    if (!mounted || _selectedId != document.id || saved == null) return;
    setState(() {
      _controller.text = saved.text;
      _entities = saved.entities;
    });
  }

  Future<void> _extract(List<WorkDocument> documents) async {
    final String? id = _selectedId;
    if (id == null) return;
    WorkDocument? selected;
    for (final WorkDocument document in documents) {
      if (document.id == id) {
        selected = document;
        break;
      }
    }
    if (selected == null) return;

    setState(() => _busy = true);
    try {
      final OcrDocumentResult result = await ref.read(ocrServiceProvider).extract(selected);
      if (mounted) {
        setState(() {
          _controller.text = result.text;
          _entities = result.entities;
        });
      }
    } on AppFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.localizedFailure(error))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.unableExtractText)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveEdited() async {
    final String? id = _selectedId;
    if (id == null) return;
    final OcrDocumentResult result =
        await ref.read(ocrServiceProvider).saveEdited(id, _controller.text);
    if (mounted) {
      setState(() => _entities = result.entities);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ocrSaved)),
      );
    }
  }
}

class _EntitySection extends StatelessWidget {
  const _EntitySection({required this.entities});

  final SmartEntities entities;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (entities.isEmpty) return Text(l10n.noSmartEntities);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l10n.smartExtraction, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _chips(l10n.email, entities.emails),
        _chips(l10n.phone, entities.phones),
        _chips(l10n.date, entities.dates),
        _chips(l10n.url, entities.urls),
        _chips(l10n.money, entities.money),
      ],
    );
  }

  Widget _chips(String label, List<String> values) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: values.map((value) => Chip(label: Text(value))).toList(growable: false),
          ),
        ],
      ),
    );
  }
}
