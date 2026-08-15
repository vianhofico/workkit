import 'package:flutter/material.dart';
import 'package:workkit/app/router/app_router.dart';
import 'package:workkit/core/theme/app_theme.dart';

class WorkKitApp extends StatelessWidget {
  const WorkKitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WorkKit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
