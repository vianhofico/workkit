import 'package:flutter/material.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const sections = <String, List<String>>{
      'Document': <String>['Scan document', 'OCR', 'Image to PDF'],
      'PDF': <String>['Merge', 'Split', 'Reorder', 'Sign'],
      'Image': <String>['Compress', 'Resize', 'Convert'],
      'QR': <String>['Scan QR', 'Create QR'],
    };

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text('Tools', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        const SearchBar(leading: Icon(Icons.search), hintText: 'Search tools'),
        const SizedBox(height: 24),
        ...sections.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...entry.value.map(
                  (tool) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.chevron_right),
                    title: Text(tool),
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
