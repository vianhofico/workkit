import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import 'package:workkit/features/documents/application/document_providers.dart';
import 'package:workkit/features/documents/domain/work_document.dart';
import 'package:workkit/features/signature/application/signature_providers.dart';
import 'package:workkit/features/signature/application/signature_service.dart';
import 'package:workkit/features/signature/domain/saved_signature.dart';
import 'package:workkit/features/signature/domain/signature_pdf_engine.dart';

class SignatureScreen extends ConsumerStatefulWidget {
  const SignatureScreen({super.key});

  @override
  ConsumerState<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends ConsumerState<SignatureScreen> {
  late final SignatureController _signatureController;
  final TextEditingController _name = TextEditingController(text: 'My signature');
  final TextEditingController _page = TextEditingController(text: '1');
  final TextEditingController _x = TextEditingController(text: '50');
  final TextEditingController _y = TextEditingController(text: '50');
  final TextEditingController _width = TextEditingController(text: '160');
  final TextEditingController _height = TextEditingController(text: '60');
  final TextEditingController _password = TextEditingController();

  String? _selectedDocumentId;
  String? _selectedSignatureId;
  PdfPageGeometry? _geometry;
  double _rotation = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _name.dispose();
    _page.dispose();
    _x.dispose();
    _y.dispose();
    _width.dispose();
    _height.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<WorkDocument>> documentsAsync = ref.watch(documentsProvider);
    final AsyncValue<List<SavedSignature>> signaturesAsync = ref.watch(signaturesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Signature')),
      body: documentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(child: Text('Unable to load documents.')),
        data: (documents) => signaturesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const Center(child: Text('Unable to load saved signatures.')),
          data: (signatures) => _content(documents, signatures),
        ),
      ),
    );
  }

  Widget _content(List<WorkDocument> documents, List<SavedSignature> signatures) {
    final List<WorkDocument> pdfs = documents.where((item) => item.type == 'pdf').toList();
    final WorkDocument? selectedDocument = _findDocument(pdfs, _selectedDocumentId);
    final SavedSignature? selectedSignature = _findSignature(signatures, _selectedSignatureId);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text('Draw and save', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Signatures stay on this device and are saved as transparent PNG files.'),
        const SizedBox(height: 16),
        Container(
          height: 180,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Signature(
            controller: _signatureController,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Signature name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: _busy ? null : _signatureController.clear,
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _saveSignature,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save signature'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text('Saved signatures', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (signatures.isEmpty)
          const Text('No saved signature yet.')
        else
          ...signatures.map(
            (signature) {
              final bool selected = _selectedSignatureId == signature.id;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                selected: selected,
                onTap: _busy ? null : () => setState(() => _selectedSignatureId = signature.id),
                leading: Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(signature.name),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 56,
                      width: 160,
                      color: Colors.white,
                      padding: const EdgeInsets.all(4),
                      child: Image.file(File(signature.path), fit: BoxFit.contain),
                    ),
                  ),
                ),
                trailing: IconButton(
                  tooltip: 'Delete signature',
                  onPressed: _busy ? null : () => _deleteSignature(signature),
                  icon: const Icon(Icons.delete_outline),
                ),
              );
            },
          ),
        const Divider(height: 40),
        Text('Place on PDF', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Coordinates and size use PDF points. Page numbers shown here start at 1.'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedDocumentId,
          decoration: const InputDecoration(labelText: 'PDF document', border: OutlineInputBorder()),
          items: pdfs
              .map((item) => DropdownMenuItem<String>(value: item.id, child: Text(item.name)))
              .toList(),
          onChanged: _busy
              ? null
              : (value) => setState(() {
                    _selectedDocumentId = value;
                    _geometry = null;
                  }),
        ),
        if (pdfs.isEmpty) ...<Widget>[
          const SizedBox(height: 8),
          const Text('Import or create a PDF first.'),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _page,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Page', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'PDF password (only if protected)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy || selectedDocument == null ? null : () => _checkGeometry(selectedDocument),
          icon: const Icon(Icons.straighten),
          label: const Text('Check page size'),
        ),
        if (_geometry != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            'Page size: ${_geometry!.width.toStringAsFixed(0)} × ${_geometry!.height.toStringAsFixed(0)} pt',
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(child: _numberField(_x, 'X')),
            const SizedBox(width: 12),
            Expanded(child: _numberField(_y, 'Y')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(child: _numberField(_width, 'Width')),
            const SizedBox(width: 12),
            Expanded(child: _numberField(_height, 'Height')),
          ],
        ),
        const SizedBox(height: 16),
        Text('Rotation: ${_rotation.round()}°'),
        Slider(
          value: _rotation,
          min: -180,
          max: 180,
          divisions: 72,
          label: '${_rotation.round()}°',
          onChanged: _busy ? null : (value) => setState(() => _rotation = value),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _busy || selectedDocument == null || selectedSignature == null
              ? null
              : () => _signPdf(selectedDocument, selectedSignature),
          icon: const Icon(Icons.draw_outlined),
          label: const Text('Create signed copy'),
        ),
        if (_busy) ...<Widget>[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }

  WorkDocument? _findDocument(List<WorkDocument> documents, String? id) {
    if (id == null) return null;
    for (final WorkDocument document in documents) {
      if (document.id == id) return document;
    }
    return null;
  }

  SavedSignature? _findSignature(List<SavedSignature> signatures, String? id) {
    if (id == null) return null;
    for (final SavedSignature signature in signatures) {
      if (signature.id == id) return signature;
    }
    return null;
  }

  Future<void> _saveSignature() async {
    setState(() => _busy = true);
    try {
      final bytes = await _signatureController.toPngBytes(width: 800, height: 300);
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException('Draw a signature before saving.');
      }
      final SignatureService service = await ref.read(signatureServiceProvider.future);
      final SavedSignature saved = await service.saveSignature(_name.text, bytes);
      _signatureController.clear();
      if (mounted) {
        setState(() => _selectedSignatureId = saved.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signature saved locally.')),
        );
      }
    } on FormatException catch (error) {
      _show(error.message);
    } catch (_) {
      _show('Unable to save signature.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteSignature(SavedSignature signature) async {
    setState(() => _busy = true);
    try {
      final SignatureService service = await ref.read(signatureServiceProvider.future);
      await service.deleteSignature(signature);
      if (mounted && _selectedSignatureId == signature.id) {
        setState(() => _selectedSignatureId = null);
      }
    } catch (_) {
      _show('Unable to delete signature.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkGeometry(WorkDocument document) async {
    setState(() => _busy = true);
    try {
      final int page = _pageIndex();
      final SignatureService service = await ref.read(signatureServiceProvider.future);
      final PdfPageGeometry geometry = await service.pageGeometry(
        document,
        page,
        password: _normalizedPassword,
      );
      if (mounted) setState(() => _geometry = geometry);
    } on SignaturePdfException catch (error) {
      _show(error.message);
    } on FormatException catch (error) {
      _show(error.message);
    } catch (_) {
      _show('Unable to inspect the PDF page.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signPdf(WorkDocument document, SavedSignature signature) async {
    setState(() => _busy = true);
    try {
      final PdfSignaturePlacement placement = PdfSignaturePlacement(
        page: _pageIndex(),
        x: _double(_x, 'X'),
        y: _double(_y, 'Y'),
        width: _double(_width, 'Width'),
        height: _double(_height, 'Height'),
        rotationDegrees: _rotation,
      );
      final SignatureService service = await ref.read(signatureServiceProvider.future);
      final WorkDocument output = await service.signPdf(
        document,
        signature,
        placement,
        password: _normalizedPassword,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved ${output.name} to WorkKit.')),
        );
      }
    } on SignaturePdfException catch (error) {
      _show(error.message);
    } on FormatException catch (error) {
      _show(error.message);
    } catch (_) {
      _show('Unable to create signed PDF.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int _pageIndex() {
    final int? value = int.tryParse(_page.text.trim());
    if (value == null || value < 1) {
      throw const FormatException('Page must be 1 or greater.');
    }
    return value - 1;
  }

  double _double(TextEditingController controller, String field) {
    final double? value = double.tryParse(controller.text.trim());
    if (value == null) {
      throw FormatException('$field must be a number.');
    }
    return value;
  }

  String? get _normalizedPassword {
    final String value = _password.text.trim();
    return value.isEmpty ? null : value;
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
