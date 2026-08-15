import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/features/documents/application/document_providers.dart';
import 'package:workkit/features/documents/domain/work_document.dart';

class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen> {
  String _query = '';
  bool _favoritesOnly = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<WorkDocument>> documents = ref.watch(documentsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Files',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: _isImporting ? null : _importDocument,
              icon: _isImporting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_open_outlined),
              label: Text(_isImporting ? 'Importing' : 'Import'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SearchBar(
          leading: const Icon(Icons.search),
          hintText: 'Search documents',
          onChanged: (String value) {
            setState(() => _query = value.trim().toLowerCase());
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            FilterChip(
              label: const Text('Favorites'),
              selected: _favoritesOnly,
              onSelected: (bool value) {
                setState(() => _favoritesOnly = value);
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        documents.when(
          data: (List<WorkDocument> items) {
            final List<WorkDocument> visible = items.where((WorkDocument item) {
              final bool matchesFavorite = !_favoritesOnly || item.isFavorite;
              final bool matchesQuery = _query.isEmpty ||
                  item.name.toLowerCase().contains(_query) ||
                  item.type.toLowerCase().contains(_query);
              return matchesFavorite && matchesQuery;
            }).toList(growable: false);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _LibrarySummary(documents: items),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  _EmptyFilesState(
                    hasDocuments: items.isNotEmpty,
                    filtered: _query.isNotEmpty || _favoritesOnly,
                  )
                else
                  ...visible.map(
                    (WorkDocument document) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DocumentTile(
                        document: document,
                        onToggleFavorite: () => _toggleFavorite(document),
                        onRename: () => _renameDocument(document),
                        onDelete: () => _deleteDocument(document),
                        onShare: (Rect origin) => _shareDocument(document, origin),
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (Object error, StackTrace stackTrace) => const _FilesErrorState(),
        ),
      ],
    );
  }

  Future<void> _importDocument() async {
    setState(() => _isImporting = true);
    try {
      final service = await ref.read(documentLibraryServiceProvider.future);
      final WorkDocument? document = await service.importFromDevice();
      if (!mounted || document == null) {
        return;
      }
      _showMessage('Imported ${document.name}');
    } catch (error) {
      if (mounted) {
        _showMessage('Could not import this file. $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _toggleFavorite(WorkDocument document) async {
    try {
      await ref.read(documentRepositoryProvider).setFavorite(
            document.id,
            isFavorite: !document.isFavorite,
          );
    } catch (error) {
      if (mounted) {
        _showMessage('Could not update favorite. $error');
      }
    }
  }

  Future<void> _renameDocument(WorkDocument document) async {
    final TextEditingController controller = TextEditingController(
      text: document.name,
    );
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Rename document'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Name'),
            onSubmitted: (String value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(dialogContext).pop(value);
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.of(dialogContext).pop(controller.text);
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (newName == null || newName.trim() == document.name) {
      return;
    }

    try {
      final service = await ref.read(documentLibraryServiceProvider.future);
      await service.rename(document, newName);
    } catch (error) {
      if (mounted) {
        _showMessage('Could not rename this document. $error');
      }
    }
  }

  Future<void> _deleteDocument(WorkDocument document) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Delete document?'),
              content: Text(
                '${document.name} will be removed from this device. This cannot be undone.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    try {
      final service = await ref.read(documentLibraryServiceProvider.future);
      await service.delete(document);
      if (mounted) {
        _showMessage('Deleted ${document.name}');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Could not delete this document. $error');
      }
    }
  }

  Future<void> _shareDocument(WorkDocument document, Rect origin) async {
    try {
      await ref.read(documentShareServiceProvider).share(
            document,
            sharePositionOrigin: origin,
          );
    } catch (error) {
      if (mounted) {
        _showMessage('Could not share this document. $error');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LibrarySummary extends StatelessWidget {
  const _LibrarySummary({required this.documents});

  final List<WorkDocument> documents;

  @override
  Widget build(BuildContext context) {
    final int totalBytes = documents.fold<int>(
      0,
      (int total, WorkDocument document) => total + document.sizeBytes,
    );
    final int favoriteCount = documents
        .where((WorkDocument document) => document.isFavorite)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Wrap(
          spacing: 18,
          runSpacing: 8,
          children: <Widget>[
            _SummaryItem(
              icon: Icons.description_outlined,
              label: '${documents.length} files',
            ),
            _SummaryItem(
              icon: Icons.storage_outlined,
              label: _formatSize(totalBytes),
            ),
            _SummaryItem(
              icon: Icons.star_outline,
              label: '$favoriteCount favorites',
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.document,
    required this.onToggleFavorite,
    required this.onRename,
    required this.onDelete,
    required this.onShare,
  });

  final WorkDocument document;
  final VoidCallback onToggleFavorite;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final ValueChanged<Rect> onShare;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        leading: _DocumentThumbnail(document: document),
        title: Text(
          document.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_labelForType(document.type)} · ${_formatSize(document.sizeBytes)} · ${_formatUpdated(document.updatedAt)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              tooltip: document.isFavorite ? 'Remove favorite' : 'Add favorite',
              onPressed: onToggleFavorite,
              icon: Icon(
                document.isFavorite ? Icons.star : Icons.star_border,
              ),
            ),
            Builder(
              builder: (BuildContext menuContext) {
                return PopupMenuButton<_DocumentAction>(
                  tooltip: 'Document actions',
                  onSelected: (_DocumentAction action) {
                    switch (action) {
                      case _DocumentAction.share:
                        final RenderBox? box =
                            menuContext.findRenderObject() as RenderBox?;
                        final Rect origin = box == null
                            ? const Rect.fromLTWH(0, 0, 1, 1)
                            : box.localToGlobal(Offset.zero) & box.size;
                        onShare(origin);
                      case _DocumentAction.rename:
                        onRename();
                      case _DocumentAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (BuildContext context) => const <
                      PopupMenuEntry<_DocumentAction>>[
                    PopupMenuItem<_DocumentAction>(
                      value: _DocumentAction.share,
                      child: ListTile(
                        leading: Icon(Icons.ios_share_outlined),
                        title: Text('Share / export'),
                      ),
                    ),
                    PopupMenuItem<_DocumentAction>(
                      value: _DocumentAction.rename,
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Rename'),
                      ),
                    ),
                    PopupMenuItem<_DocumentAction>(
                      value: _DocumentAction.delete,
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentThumbnail extends StatelessWidget {
  const _DocumentThumbnail({required this.document});

  final WorkDocument document;

  @override
  Widget build(BuildContext context) {
    if (document.type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox.square(
          dimension: 44,
          child: Image.file(
            File(document.path),
            fit: BoxFit.cover,
            cacheWidth: 128,
            errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
              return _FileIcon(type: document.type);
            },
          ),
        ),
      );
    }

    return _FileIcon(type: document.type);
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final IconData icon = switch (type) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'image' => Icons.image_outlined,
      'text' => Icons.text_snippet_outlined,
      'spreadsheet' => Icons.table_chart_outlined,
      'presentation' => Icons.slideshow_outlined,
      'document' => Icons.article_outlined,
      _ => Icons.insert_drive_file_outlined,
    };

    return SizedBox.square(
      dimension: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon),
      ),
    );
  }
}

class _EmptyFilesState extends StatelessWidget {
  const _EmptyFilesState({
    required this.hasDocuments,
    required this.filtered,
  });

  final bool hasDocuments;
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final String title = filtered && hasDocuments
        ? 'No matching documents.'
        : 'No documents yet.';
    final String subtitle = filtered && hasDocuments
        ? 'Try another search or remove the favorites filter.'
        : 'Import a file to start your local library.';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: <Widget>[
          const Icon(Icons.folder_open_outlined, size: 42),
          const SizedBox(height: 12),
          Text(title),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _FilesErrorState extends StatelessWidget {
  const _FilesErrorState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: <Widget>[
          Icon(Icons.error_outline, size: 42),
          SizedBox(height: 12),
          Text('Could not load your documents.'),
          SizedBox(height: 4),
          Text('Your local files were not modified.'),
        ],
      ),
    );
  }
}

enum _DocumentAction { share, rename, delete }

String _labelForType(String type) {
  return switch (type) {
    'pdf' => 'PDF',
    'image' => 'Image',
    'text' => 'Text',
    'spreadsheet' => 'Spreadsheet',
    'presentation' => 'Presentation',
    'document' => 'Document',
    _ => 'File',
  };
}

String _formatUpdated(DateTime value) {
  final DateTime now = DateTime.now();
  final DateTime date = DateTime(value.year, value.month, value.day);
  final DateTime today = DateTime(now.year, now.month, now.day);
  final int days = today.difference(date).inDays;

  if (days == 0) {
    return 'Today';
  }
  if (days == 1) {
    return 'Yesterday';
  }
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
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
  if (megabytes < 1024) {
    return '${megabytes.toStringAsFixed(1)} MB';
  }
  final double gigabytes = megabytes / 1024;
  return '${gigabytes.toStringAsFixed(1)} GB';
}
