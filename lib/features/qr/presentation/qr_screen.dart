import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:workkit/core/localization/localization_extensions.dart';
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
    final l10n = context.l10n;
    final AsyncValue<List<QrHistoryEntry>> historyAsync = ref.watch(qrHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qrTools)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          SegmentedButton<_QrMode>(
            segments: <ButtonSegment<_QrMode>>[
              ButtonSegment(value: _QrMode.scan, icon: const Icon(Icons.qr_code_scanner), label: Text(l10n.scanMode)),
              ButtonSegment(value: _QrMode.create, icon: const Icon(Icons.qr_code_2), label: Text(l10n.createMode)),
              ButtonSegment(value: _QrMode.history, icon: const Icon(Icons.history), label: Text(l10n.history)),
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
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l10n.scanQr, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(l10n.qrScanDescription),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MobileScanner(
              controller: _scanner,
              onDetect: (capture) => unawaited(_recordCapture(capture)),
            ),
          ),
        ),
        if (_lastScanned != null) ...<Widget>[
          const SizedBox(height: 16),
          Text(l10n.lastResult, style: Theme.of(context).textTheme.titleMedium),
          SelectableText(_lastScanned!),
        ],
      ],
    );
  }

  Widget _createView() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l10n.createQr, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(l10n.qrCreateDescription),
        const SizedBox(height: 16),
        TextField(
          controller: _content,
          minLines: 2,
          maxLines: 5,
          decoration: InputDecoration(labelText: l10n.qrContent, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _generate,
          icon: const Icon(Icons.qr_code_2),
          label: Text(l10n.generateSaveHistory),
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
    final l10n = context.l10n;
    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text(l10n.unableLoadQrHistory),
      data: (entries) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(l10n.localHistory, style: Theme.of(context).textTheme.headlineSmall)),
              TextButton.icon(
                onPressed: entries.isEmpty || _busy ? null : _clearHistory,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(l10n.clear),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Text(l10n.noQrHistory)
          else
            ...entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(entry.isGenerated ? Icons.qr_code_2 : Icons.qr_code_scanner),
                title: Text(entry.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${entry.isGenerated ? l10n.generated : l10n.scanned} • '
                  '${DateFormat.yMd(l10n.localeName).add_Hm().format(entry.createdAt.toLocal())}',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _recordCapture(BarcodeCapture capture) async {
    final l10n = context.l10n;
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
            SnackBar(content: Text(l10n.qrSavedHistory)),
          );
        }
      } catch (_) {
        _show(l10n.qrSaveFailed);
      }
      return;
    }
  }

  Future<void> _generate() async {
    final l10n = context.l10n;
    final String value = _content.text.trim();
    if (value.isEmpty) {
      _show(l10n.enterQrContent);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(qrServiceProvider).recordGenerated(value);
      if (mounted) setState(() => _generated = value);
    } catch (_) {
      _show(l10n.generatedQrSaveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearHistory() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await ref.read(qrServiceProvider).clearHistory();
    } catch (_) {
      _show(l10n.qrClearFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
