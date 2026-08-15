import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/features/documents/application/document_providers.dart';
import 'package:workkit/features/documents/domain/work_document.dart';

class FilesScreen extends ConsumerWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<WorkDocument>> documents = ref.watch(documentsProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text('Files', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        const SearchBar(leading: Icon(Icons.search), hintText: 'Search documents'),
        const SizedBox(height: 24),
        documents.when(
          data: (items) {
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: <Widget>[
                    Icon(Icons.folder_open_outlined, size: 42),
                    SizedBox(height: 12),
                    Text('No documents yet.'),
                    SizedBox(height: 4),
                    Text('Scan or import a file to get started.'),
                  ],
                ),
              );
            }
            return Column(
              children: items.map((document) => _DocumentTile(document: document)).toList(growable: false),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const Text('Could not load your documents. Your local files were not modified.'),
        ),
      ],
    );
  }
}

class _DocumentTile extends ConsumerWidget {
  const _DocumentTile({required this.document});

  final WorkDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(document.name),
        subtitle: Text('${document.sizeBytes} bytes'),
        trailing: IconButton(
          tooltip: document.isFavorite ? 'Remove favorite' : 'Add favorite',
          onPressed: () => ref.read(documentRepositoryProvider).setFavorite(
                document.id,
                isFavorite: !document.isFavorite,
              ),
          icon: Icon(document.isFavorite ? Icons.star : Icons.star_border),
        ),
      ),
    );
  }
}
