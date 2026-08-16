import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workkit/app/router/app_router.dart';
import 'package:workkit/core/localization/app_locale.dart';
import 'package:workkit/core/localization/locale_provider.dart';
import 'package:workkit/core/theme/app_theme.dart';
import 'package:workkit/l10n/app_localizations.dart';

class WorkKitApp extends ConsumerWidget {
  const WorkKitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppLocalePreference> preference =
        ref.watch(localePreferenceProvider);
    final Locale? locale = preference.value?.locale;

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const <Locale>[
        Locale('en'),
        Locale('vi'),
      ],
      routerConfig: appRouter,
    );
  }
}
