import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: Semantics(
        container: true,
        label: 'Primary navigation',
        child: NavigationBar(
          selectedIndex: _currentIndex(context),
          onDestinationSelected: (int index) => context.go(_locations[index]),
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'Files',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Tools',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
