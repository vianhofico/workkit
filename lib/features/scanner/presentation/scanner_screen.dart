import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/core/errors/app_failure.dart';
import 'package:workkit/features/documents/domain/work_document.dart';
import 'package:workkit/features/scanner/application/scanner_providers.dart';
import 'package:workkit/features/scanner/application/scanner_service.dart';
import 'package:workkit/features/scanner/domain/document_scanner.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  bool _busy = false;
  List<WorkDocument> _lastSaved = const <WorkDocument>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document scanner')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            'Scan locally',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Android uses ML Kit and iOS uses VisionKit. Crop, edge detection, rotation and enhancement happen in the native scanner UI; completed files are copied into WorkKit storage.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _ScanCard(
            icon: Icons.photo_library_outlined,
            title: 'Scan as images',
            subtitle: 'Best when you want one managed image per page.',
            enabled: !_busy,
            onPressed: () => _scan(ScanOutputFormat.images),
          ),
          const SizedBox(height: 12),
          _ScanCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Scan as PDF',
            subtitle: 'Best for a multi-page document kept together as a PDF.',
            enabled: !_busy,
            onPressed: () => _scan(ScanOutputFormat.pdf),
          ),
          if (_busy) ...<Widget>[
            const SizedBox(height: 24),
            const LinearProgressIndicator(),
          ],
          if (_lastSaved.isNotEmpty) ...<Widget>[
            const SizedBox(height: 28),
            Text('Saved to WorkKit', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ..._lastSaved.map(
              (WorkDocument document) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  document.type == 'pdf'
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                ),
                title: Text(document.name),
                subtitle: Text('${document.sizeBytes} bytes'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _scan(ScanOutputFormat format) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final ScannerService service = await ref.read(scannerServiceProvider.future);
      final List<WorkDocument>? saved = await service.scanAndSave(format);
      if (!mounted) {
        return;
      }
      if (saved == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan cancelled. No files were saved.')),
        );
        return;
      }
      setState(() => _lastSaved = saved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${saved.length} scanned file(s).')),
      );
    } on AppFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to complete the scan.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: enabled ? onPressed : null,
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}
