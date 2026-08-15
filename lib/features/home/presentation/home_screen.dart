import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    const actions = <(IconData, String)>[
      (Icons.document_scanner_outlined, 'Scan'),
      (Icons.text_snippet_outlined, 'OCR'),
      (Icons.picture_as_pdf_outlined, 'PDF'),
      (Icons.qr_code_scanner_outlined, 'QR'),
      (Icons.draw_outlined, 'Sign'),
      (Icons.image_outlined, 'Image'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: <Widget>[
        Text('WorkKit', style: textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('Everyday work tools. Private by default.', style: textTheme.bodyMedium),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.document_scanner_outlined),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('Scan a document'),
          ),
        ),
        const SizedBox(height: 28),
        Text('Quick actions', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final (IconData icon, String label) = actions[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {},
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[Icon(icon), const SizedBox(height: 8), Text(label)],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        Text('Recent', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: <Widget>[
                Icon(Icons.folder_open_outlined),
                SizedBox(width: 14),
                Expanded(child: Text('Your recent scans and files will appear here.')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
