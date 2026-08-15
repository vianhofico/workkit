import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workkit/features/documents/application/document_providers.dart';
import 'package:workkit/features/documents/domain/work_document.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AsyncValue<List<WorkDocument>> documents = ref.watch(documentsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: <Widget>[
        Text('WorkKit', style: textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Everyday work tools. Private by default.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => _importDocument(context, ref),
          icon: const Icon(Icons.file_open_outlined),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('Import a file'),
          ),
        ),
        const SizedBox(height: 28),
        Text('Quick actions', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        const _QuickActionGrid(),
        const SizedBox(height: 28),
        Row(
          children: <Widget>[
            Expanded(child: Text('Recent', style: textTheme.titleMedium)),
            TextButton(
              onPressed: () => context.go('/files'),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        documents.when(
          data: (List<WorkDocument> items) {
            if (items.isEmpty) {
              return const _EmptyRecentState();
            }
            return Column(
              children: items
                  .take(3)
                  .map(
                    (WorkDocument document) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RecentDocumentCard(document: document),
                    ),
                  )
                  .toList(growable: false),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stack) => const _EmptyRecentState(),
        ),
      ],
    );
  }

  Future<void> _importDocument(BuildContext context, WidgetRef ref) async {
    try {
      final service = await ref.read(documentLibraryServiceProvider.future);
      final WorkDocument? document = await service.importFromDevice();
      if (!context.mounted || document == null) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${document.name}')),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not import this file. $error')),
        );
      }
    }
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid();

  @override
  Widget build(BuildContext context) {
    const List<(IconData, String)> actions = <(IconData, String)>[
      (Icons.document_scanner_outlined, 'Scan'),
      (Icons.text_snippet_outlined, 'OCR'),
      (Icons.picture_as_pdf_outlined, 'PDF'),
      (Icons.qr_code_scanner_outlined, 'QR'),
      (Icons.draw_outlined, 'Sign'),
      (Icons.image_outlined, 'Image'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemCount: actions.length,
      itemBuilder: (BuildContext context, int index) {
        final (IconData icon, String label) = actions[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.go('/tools'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon),
                const SizedBox(height: 8),
                Text(label),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecentDocumentCard extends StatelessWidget {
  const _RecentDocumentCard({required this.document});

  final WorkDocument document;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: document.type == 'image'
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox.square(
                  dimension: 40,
                  child: Image.file(
                    File(document.path),
                    fit: BoxFit.cover,
                    cacheWidth: 120,
                    errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
                      return const Icon(Icons.image_outlined);
                    },
                  ),
                ),
              )
            : const Icon(Icons.description_outlined),
        title: Text(
          document.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(_formatSize(document.sizeBytes)),
        trailing: document.isFavorite ? const Icon(Icons.star, size: 20) : null,
        onTap: () => context.go('/files'),
      ),
    );
  }
}

class _EmptyRecentState extends StatelessWidget {
  const _EmptyRecentState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            const Icon(Icons.folder_open_outlined),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Your recent imports and scans will appear here.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final double kilobytes = bytes / 1024;
  if (kilobytes < 1024) {
    return '${kilobytes.toStringAsFixed(1)} KB';
  }
  final double megabytes = kilobytes / 1024;
  return '${megabytes.toStringAsFixed(1)} MB';
}
