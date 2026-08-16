import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workkit/core/localization/localization_extensions.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const List<String> _locations = <String>[
    '/',
    '/files',
    '/tools',
    '/settings',
  ];

  int _currentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final int exact = _locations.indexOf(location);
    return exact == -1 ? 0 : exact;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: Semantics(
        container: true,
        label: l10n.primaryNavigation,
        child: NavigationBar(
          selectedIndex: _currentIndex(context),
          onDestinationSelected: (int index) => context.go(_locations[index]),
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.folder_outlined),
              selectedIcon: const Icon(Icons.folder),
              label: l10n.files,
            ),
            NavigationDestination(
              icon: const Icon(Icons.grid_view_outlined),
              selectedIcon: const Icon(Icons.grid_view),
              label: l10n.tools,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l10n.settings,
            ),
          ],
        ),
      ),
    );
  }
}
