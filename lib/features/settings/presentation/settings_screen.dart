import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:workkit/core/backup/backup_provider.dart';
import 'package:workkit/core/backup/backup_service.dart';
import 'package:workkit/core/errors/app_failure.dart';
import 'package:workkit/core/localization/app_locale.dart';
import 'package:workkit/core/localization/locale_provider.dart';
import 'package:workkit/core/localization/localization_extensions.dart';
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
    final l10n = context.l10n;
    final AsyncValue<AppRecoverySummary> recovery = ref.watch(appRecoveryProvider);
    final AsyncValue<AppLocalePreference> localeAsync = ref.watch(localePreferenceProvider);
    final AppLocalePreference locale = localeAsync.value ?? AppLocalePreference.system;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(l10n.settings, style: Theme.of(context).textTheme.headlineMedium),
        ),
        const SizedBox(height: 20),
        Text(l10n.language, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<AppLocalePreference>(
          initialValue: locale,
          decoration: InputDecoration(
            labelText: l10n.appLanguage,
            border: const OutlineInputBorder(),
          ),
          items: <DropdownMenuItem<AppLocalePreference>>[
            DropdownMenuItem(
              value: AppLocalePreference.system,
              child: Text(l10n.systemDefault),
            ),
            DropdownMenuItem(
              value: AppLocalePreference.vietnamese,
              child: Text(l10n.vietnamese),
            ),
            DropdownMenuItem(
              value: AppLocalePreference.english,
              child: Text(l10n.english),
            ),
          ],
          onChanged: _busy
              ? null
              : (value) async {
                  if (value == null) return;
                  await ref.read(localeRepositoryProvider).setPreference(value);
                },
        ),
        const SizedBox(height: 20),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_outline),
          title: Text(l10n.privacy),
          subtitle: Text(l10n.privacySubtitle),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.cloud_off_outlined),
          title: Text(l10n.offlineFirst),
          subtitle: Text(l10n.offlineSubtitle),
        ),
        const Divider(height: 32),
        Text(l10n.backupRecovery, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(l10n.backupDescription),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: _busy ? null : _createBackup,
          icon: const Icon(Icons.backup_outlined),
          label: Text(l10n.createShareBackup),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _restoreBackup,
          icon: const Icon(Icons.restore_outlined),
          label: Text(l10n.restoreFromBackup),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _recoverStorage,
          icon: const Icon(Icons.cleaning_services_outlined),
          label: Text(l10n.recoverStorage),
        ),
        const SizedBox(height: 12),
        recovery.when(
          data: (summary) => Text(
            l10n.startupRecovery(
              summary.interruptedJobs,
              _formatBytes(summary.recoveredBytes),
            ),
          ),
          loading: () => Text(l10n.checkingRecovery),
          error: (error, stack) => Text(l10n.recoveryUnavailable),
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
          title: context.l10n.backupShareTitle,
          subject: context.l10n.backupShareTitle,
          sharePositionOrigin: Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: 1,
            height: 1,
          ),
        ),
      );
      _show(context.l10n.backupCreated);
    } on AppFailure catch (error) {
      _show(context.localizedFailure(error));
    } catch (_) {
      _show(context.l10n.backupCreateFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final PickedDocument? selected = await ref.read(documentPickerProvider).pick();
    if (selected == null || !mounted) return;
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(dialogContext.l10n.restoreBackupTitle),
            content: Text(dialogContext.l10n.restoreBackupDescription),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(dialogContext.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(dialogContext.l10n.restore),
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
      _show(context.l10n.restoredSummary(summary.documents, summary.signatures));
    } on AppFailure catch (error) {
      _show(context.localizedFailure(error));
    } catch (_) {
      _show(context.l10n.backupRestoreFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recoverStorage() async {
    setState(() => _busy = true);
    try {
      final storage = await ref.read(localFileServiceProvider.future);
      final int bytes = await storage.recoverAbandonedFiles();
      _show(context.l10n.recoveredTemporary(_formatBytes(bytes)));
    } catch (_) {
      _show(context.l10n.storageRecoveryFailed);
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
