import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/app/workkit_app.dart';
import 'package:workkit/core/recovery/recovery_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ProviderContainer container = ProviderContainer();
  try {
    await container.read(appRecoveryProvider.future);
  } catch (_) {
    // Recovery is best-effort and must never prevent the app from starting.
  }
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const WorkKitApp(),
    ),
  );
}
