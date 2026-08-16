import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workkit/core/localization/localization_extensions.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final List<_ToolSection> sections = <_ToolSection>[
      _ToolSection(
        title: l10n.documentSection,
        tools: <_ToolItem>[
          _ToolItem(l10n.scanDocument, Icons.document_scanner_outlined, '/tools/scanner'),
          _ToolItem(l10n.ocr, Icons.text_snippet_outlined, '/tools/ocr'),
          _ToolItem(l10n.imageToPdf, Icons.picture_as_pdf_outlined, '/tools/pdf'),
        ],
      ),
      _ToolSection(
        title: l10n.pdf,
        tools: <_ToolItem>[
          _ToolItem(l10n.mergeSplit, Icons.merge_type, '/tools/pdf'),
          _ToolItem(l10n.reorderDelete, Icons.reorder, '/tools/pdf'),
          _ToolItem(l10n.rotateExportImages, Icons.rotate_right, '/tools/pdf'),
          _ToolItem(l10n.sign, Icons.draw_outlined, '/tools/signature'),
        ],
      ),
      _ToolSection(
        title: l10n.image,
        tools: <_ToolItem>[
          _ToolItem(l10n.compress, Icons.compress, '/tools/image'),
          _ToolItem(l10n.resize, Icons.aspect_ratio, '/tools/image'),
          _ToolItem(l10n.crop, Icons.crop, '/tools/image'),
          _ToolItem(l10n.convert, Icons.transform, '/tools/image'),
          _ToolItem(l10n.removeMetadata, Icons.privacy_tip_outlined, '/tools/image'),
        ],
      ),
      _ToolSection(
        title: l10n.qr,
        tools: <_ToolItem>[
          _ToolItem(l10n.scanQr, Icons.qr_code_scanner, '/tools/qr'),
          _ToolItem(l10n.createQr, Icons.qr_code_2, '/tools/qr'),
        ],
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text(l10n.tools, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        SearchBar(leading: const Icon(Icons.search), hintText: l10n.searchTools),
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
                        ? Chip(label: Text(l10n.comingSoon))
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
