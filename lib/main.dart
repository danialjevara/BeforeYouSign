import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'localization/app_copy.dart';
import 'router.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const Material(
      color: Color(0xFF0D1117),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Something went wrong.\nPlease restart the app.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFFB300),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  };
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _logStartupIssue(
      'Flutter startup error: ${details.exceptionAsString()}',
      details.stack,
    );
  };

  try {
    await FlutterGemma.initialize(
      maxDownloadRetries: 3,
    );
  } catch (e, stackTrace) {
    _logStartupIssue('Gemma bootstrap failed: $e', stackTrace);
  }

  final container = ProviderContainer();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BeforeYouSignApp(),
    ),
  );
}

void _logStartupIssue(String message, StackTrace? stackTrace) {
  if (!kDebugMode) {
    return;
  }

  debugPrint(message);
  if (stackTrace != null) {
    debugPrintStack(stackTrace: stackTrace);
  }
}

class BeforeYouSignApp extends StatelessWidget {
  const BeforeYouSignApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Before You Sign',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: AppCopy.supportedLocales,
      localeResolutionCallback: (deviceLocale, _) {
        return AppCopy.resolveLocale(deviceLocale);
      },
      routerConfig: appRouter,
    );
  }
}
