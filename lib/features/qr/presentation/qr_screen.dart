import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:workkit/features/qr/application/qr_providers.dart';
import 'package:workkit/features/qr/domain/qr_history_entry.dart';

enum _QrMode { scan, create, history }

class QrScreen extends ConsumerStatefulWidget {
  const QrScreen({super.key});

  @override
  ConsumerState<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends ConsumerState<QrScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
  );
  final TextEditingController _content = TextEditingController();
  _QrMode _mode = _QrMode.scan;
  String? _generated;
  String? _lastScanned;
  DateTime? _lastScanAt;
  bool _busy = false;

  @override
  void dispose() {
    unawaited(_scanner.dispose());
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<QrHistoryEntry>> historyAsync = ref.watch(qrHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('QR tools')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          SegmentedButton<_QrMode>(
            segments: const <ButtonSegment<_QrMode>>[
              ButtonSegment(value: _QrMode.scan, icon: Icon(Icons.qr_code_scanner), label: Text('Scan')),
              ButtonSegment(value: _QrMode.create, icon: Icon(Icons.qr_code_2), label: Text('Create')),
              ButtonSegment(value: _QrMode.history, icon: Icon(Icons.history), label: Text('History')),
            ],
            selected: <_QrMode>{_mode},
            onSelectionChanged: _busy ? null : (values) => setState(() => _mode = values.first),
          ),
          const SizedBox(height: 20),
          switch (_mode) {
            _QrMode.scan => _scanView(),
            _QrMode.create => _createView(),
            _QrMode.history => _historyView(historyAsync),
          },
        ],
      ),
    );
  }

  Widget _scanView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Scan QR', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Camera frames are processed on-device. Detected QR content is stored only in local history.'),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MobileScanner(
              controller: _scanner,
              onDetect: (capture) {
                unawaited(_recordCapture(capture));
              },
            ),
          ),
        ),
        if (_lastScanned != null) ...<Widget>[
          const SizedBox(height: 16),
          Text('Last result', style: Theme.of(context).textTheme.titleMedium),
          SelectableText(_lastScanned!),
        ],
      ],
    );
  }

  Widget _createView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Create QR', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Generate a QR code locally from text, links, contact data, or any short payload.'),
        const SizedBox(height: 16),
        TextField(
          controller: _content,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'QR content',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _generate,
          icon: const Icon(Icons.qr_code_2),
          label: const Text('Generate and save to history'),
        ),
        if (_generated != null) ...<Widget>[
          const SizedBox(height: 24),
          Center(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: QrImageView(
                data: _generated!,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(_generated!, textAlign: TextAlign.center),
        ],
      ],
    );
  }

  Widget _historyView(AsyncValue<List<QrHistoryEntry>> historyAsync) {
    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const Text('Unable to load QR history.'),
      data: (entries) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text('Local history', style: Theme.of(context).textTheme.headlineSmall)),
              TextButton.icon(
                onPressed: entries.isEmpty || _busy ? null : _clearHistory,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Text('No QR history yet.')
          else
            ...entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(entry.isGenerated ? Icons.qr_code_2 : Icons.qr_code_scanner),
                title: Text(
                  entry.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${entry.type} • ${entry.createdAt.toLocal()}'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _recordCapture(BarcodeCapture capture) async {
    for (final Barcode barcode in capture.barcodes) {
      final String value = barcode.rawValue?.trim() ?? '';
      if (value.isEmpty) continue;
      final DateTime now = DateTime.now();
      if (_lastScanned == value &&
          _lastScanAt != null &&
          now.difference(_lastScanAt!) < const Duration(seconds: 2)) {
        return;
      }
      _lastScanned = value;
      _lastScanAt = now;
      try {
        await ref.read(qrServiceProvider).recordScan(value, format: barcode.format.name);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR saved to local history.')),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to save QR result.')),
          );
        }
      }
      return;
    }
  }

  Future<void> _generate() async {
    final String value = _content.text.trim();
    if (value.isEmpty) {
      _show('Enter QR content first.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(qrServiceProvider).recordGenerated(value);
      if (mounted) setState(() => _generated = value);
    } on FormatException catch (error) {
      _show(error.message);
    } catch (_) {
      _show('Unable to save generated QR.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearHistory() async {
    setState(() => _busy = true);
    try {
      await ref.read(qrServiceProvider).clearHistory();
    } catch (_) {
      _show('Unable to clear QR history.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
