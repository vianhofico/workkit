import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        const ListTile(
          leading: Icon(Icons.lock_outline),
          title: Text('Privacy'),
          subtitle: Text('Files stay on this device by default.'),
        ),
        const ListTile(
          leading: Icon(Icons.cloud_off_outlined),
          title: Text('Offline-first'),
          subtitle: Text('Core tools do not require an account or server.'),
        ),
      ],
    );
  }
}
