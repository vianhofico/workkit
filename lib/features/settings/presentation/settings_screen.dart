import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:workkit/core/backup/backup_provider.dart';
import 'package:workkit/core/backup/backup_service.dart';
import 'package:workkit/core/errors/app_failure.dart';
import 'package:workkit/core/recovery/recovery_provider.dart';
import 'package:workkit/core/storage/local_file_service_provider.dart';
import 'package:workkit/features/documents/application/document_providers.dart';
import 'package:workkit/features/documents/domain/document_picker.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AppRecoverySummary> recovery = ref.watch(appRecoveryProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Semantics(
          header: true,
          child: Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        ),
        const SizedBox(height: 16),
        const ListTile(
          leading: Icon(Icons.lock_outline),
          title: Text('Privacy'),
          subtitle: Text('Files stay on this device by default.'),
        ),
        const ListTile(
          leading: Icon(Icons.cloud_off_outlined),
          title: Text('Offline-first'),
          subtitle: Text('Core tools do not require an account or server.'),
        ),
        const Divider(height: 32),
        Text('Backup & recovery', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Backups contain your documents, OCR text, signatures, QR history and settings. Backup files are not encrypted, so store them securely.',
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: _busy ? null : _createBackup,
          icon: const Icon(Icons.backup_outlined),
          label: const Text('Create and share backup'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _restoreBackup,
          icon: const Icon(Icons.restore_outlined),
          label: const Text('Restore from backup'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _recoverStorage,
          icon: const Icon(Icons.cleaning_services_outlined),
          label: const Text('Recover storage'),
        ),
        const SizedBox(height: 12),
        recovery.when(
          data: (summary) => Text(
            'Startup recovery: ${summary.interruptedJobs} interrupted job(s), ${_formatBytes(summary.recoveredBytes)} temporary data cleaned.',
          ),
          loading: () => const Text('Checking recovery state…'),
          error: (error, stack) => const Text('Startup recovery status unavailable.'),
        ),
        if (_busy) ...<Widget>[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Future<void> _createBackup() async {
    setState(() => _busy = true);
    try {
      final BackupService service = await ref.read(backupServiceProvider.future);
      final File backup = await service.createBackup();
      if (!mounted) return;
      final Size size = MediaQuery.sizeOf(context);
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(backup.path)],
          title: 'WorkKit backup',
          subject: 'WorkKit backup',
          sharePositionOrigin: Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: 1,
            height: 1,
          ),
        ),
      );
      _show('Backup created locally.');
    } on AppFailure catch (error) {
      _show(error.message);
    } catch (_) {
      _show('Unable to create backup.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final PickedDocument? selected = await ref.read(documentPickerProvider).pick();
    if (selected == null || !mounted) return;
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore WorkKit backup?'),
            content: const Text(
              'Current WorkKit library records, OCR text, signatures, QR history and settings will be replaced by the backup. The selected backup itself is not modified.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Restore'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      final BackupService service = await ref.read(backupServiceProvider.future);
      final BackupRestoreSummary summary = await service.restoreBackup(selected.path);
      _show(
        'Restored ${summary.documents} document(s) and ${summary.signatures} signature(s).',
      );
    } on AppFailure catch (error) {
      _show(error.message);
    } on FormatException catch (error) {
      _show(error.message);
    } catch (_) {
      _show('Unable to restore this backup.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recoverStorage() async {
    setState(() => _busy = true);
    try {
      final storage = await ref.read(localFileServiceProvider.future);
      final int bytes = await storage.recoverAbandonedFiles();
      _show('Recovered ${_formatBytes(bytes)} of abandoned temporary data.');
    } catch (_) {
      _show('Unable to complete storage recovery.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final double kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
