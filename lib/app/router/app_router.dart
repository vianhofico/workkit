import 'package:go_router/go_router.dart';
import 'package:workkit/features/files/presentation/files_screen.dart';
import 'package:workkit/features/home/presentation/home_screen.dart';
import 'package:workkit/features/ocr/presentation/ocr_screen.dart';
import 'package:workkit/features/pdf/presentation/pdf_toolkit_screen.dart';
import 'package:workkit/features/qr/presentation/qr_screen.dart';
import 'package:workkit/features/scanner/presentation/scanner_screen.dart';
import 'package:workkit/features/settings/presentation/settings_screen.dart';
import 'package:workkit/features/shell/presentation/app_shell.dart';
import 'package:workkit/features/signature/presentation/signature_screen.dart';
import 'package:workkit/features/tools/presentation/tools_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: <RouteBase>[
        GoRoute(path: '/', name: 'home', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/files', name: 'files', builder: (context, state) => const FilesScreen()),
        GoRoute(path: '/tools', name: 'tools', builder: (context, state) => const ToolsScreen()),
        GoRoute(path: '/settings', name: 'settings', builder: (context, state) => const SettingsScreen()),
      ],
    ),
    GoRoute(path: '/tools/scanner', name: 'scanner', builder: (context, state) => const ScannerScreen()),
    GoRoute(path: '/tools/ocr', name: 'ocr', builder: (context, state) => const OcrScreen()),
    GoRoute(path: '/tools/pdf', name: 'pdf', builder: (context, state) => const PdfToolkitScreen()),
    GoRoute(path: '/tools/signature', name: 'signature', builder: (context, state) => const SignatureScreen()),
    GoRoute(path: '/tools/qr', name: 'qr', builder: (context, state) => const QrScreen()),
  ],
);
