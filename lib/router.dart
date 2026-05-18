import 'package:go_router/go_router.dart';
import 'models/analysis_data.dart';
import 'screens/onboarding_screen.dart';
import 'screens/capture_hub_screen.dart';
import 'screens/verdict_dashboard_screen.dart';
import 'screens/legal_connect_screen.dart';
import 'screens/model_download_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/onboarding',
    ),
    GoRoute(
      path: '/gemma-setup',
      builder: (context, state) => const ModelDownloadScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/capture',
      builder: (context, state) => const CaptureHubScreen(),
    ),
    GoRoute(
      path: '/verdict',
      redirect: (context, state) {
        if (state.extra == null) {
          return '/capture';
        }
        return null;
      },
      builder: (context, state) {
        final data = state.extra as AnalysisData?;
        return VerdictDashboardScreen(analysisData: data);
      },
    ),
    GoRoute(
      path: '/connect',
      redirect: (context, state) {
        if (state.extra == null) {
          return '/capture';
        }
        return null;
      },
      builder: (context, state) {
        final data = state.extra as AnalysisData?;
        return LegalConnectScreen(analysisData: data);
      },
    ),
  ],
);
