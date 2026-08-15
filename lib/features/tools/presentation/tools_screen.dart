import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const List<_ToolSection> sections = <_ToolSection>[
      _ToolSection(
        title: 'Document',
        tools: <_ToolItem>[
          _ToolItem('Scan document', Icons.document_scanner_outlined, '/tools/scanner'),
          _ToolItem('OCR', Icons.text_snippet_outlined, null),
          _ToolItem('Image to PDF', Icons.picture_as_pdf_outlined, null),
        ],
      ),
      _ToolSection(
        title: 'PDF',
        tools: <_ToolItem>[
          _ToolItem('Merge', Icons.merge_type, null),
          _ToolItem('Split', Icons.call_split, null),
          _ToolItem('Reorder', Icons.reorder, null),
          _ToolItem('Sign', Icons.draw_outlined, null),
        ],
      ),
      _ToolSection(
        title: 'Image',
        tools: <_ToolItem>[
          _ToolItem('Compress', Icons.compress, null),
          _ToolItem('Resize', Icons.aspect_ratio, null),
          _ToolItem('Convert', Icons.transform, null),
        ],
      ),
      _ToolSection(
        title: 'QR',
        tools: <_ToolItem>[
          _ToolItem('Scan QR', Icons.qr_code_scanner, null),
          _ToolItem('Create QR', Icons.qr_code_2, null),
        ],
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text('Tools', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        const SearchBar(leading: Icon(Icons.search), hintText: 'Search tools'),
        const SizedBox(height: 24),
        ...sections.map(
          (_ToolSection section) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(section.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...section.tools.map(
                  (_ToolItem tool) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(tool.icon),
                    title: Text(tool.label),
                    trailing: tool.route == null
                        ? const Chip(label: Text('Coming soon'))
                        : const Icon(Icons.chevron_right),
                    onTap: tool.route == null ? null : () => context.push(tool.route!),
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

class _ToolSection {
  const _ToolSection({required this.title, required this.tools});

  final String title;
  final List<_ToolItem> tools;
}

class _ToolItem {
  const _ToolItem(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String? route;
}
