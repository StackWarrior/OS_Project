import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'models/quiz_question.dart';
import 'routes/app_routes.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/payment_methods_screen.dart';
import 'screens/quiz_result_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/video_player_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/error_screen.dart';

class CourseLearningApp extends StatelessWidget {
  const CourseLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return MaterialApp(
      title: 'CourseLab',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: appState.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Use the builder to wrap the navigator with the error screen if needed
      // without swapping the entire MaterialApp widget.
      builder: (context, child) {
        final appState = context.watch<AppState>();
        
        if (appState.status == AppStatus.error) {
          return ErrorScreen(
            title: 'System Error',
            message: appState.errorMessage ?? 'A fatal error occurred.',
            onRetry: () => appState.init(),
          );
        }
        
        return child ?? const SizedBox.shrink();
      },
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.splash:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const SplashScreen(),
            );
          case AppRoutes.onboarding:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const OnboardingScreen(),
            );
          case AppRoutes.login:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const LoginScreen(),
            );
          case AppRoutes.register:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const RegisterScreen(),
            );
          case AppRoutes.mainShell:
            final tab = settings.arguments as int? ?? 0;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => MainShellScreen(initialTab: tab),
            );
          case AppRoutes.courseDetail:
            final id = settings.arguments as String? ?? '';
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => CourseDetailScreen(courseId: id),
            );
          case AppRoutes.videoPlayer:
            final id = settings.arguments as String? ?? '';
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => VideoPlayerScreen(courseId: id),
            );
          case AppRoutes.quiz:
            final id = settings.arguments as String? ?? '';
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => QuizScreen(courseId: id),
            );
          case AppRoutes.quizResult:
            final result = settings.arguments as QuizSessionResult?;
            if (result == null) return _errorRoute(settings);
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => QuizResultScreen(result: result),
            );
          case AppRoutes.checkout:
            final id = settings.arguments as String? ?? '';
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => CheckoutScreen(courseId: id),
            );
          case AppRoutes.admin:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (context) {
                final appState = Provider.of<AppState>(context, listen: false);
                if (appState.currentUser == null || !appState.currentUser!.isAdmin) {
                  return const _UnauthorizedAccessScreen();
                }
                return const AdminDashboardScreen();
              },
            );
          case AppRoutes.editProfile:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const EditProfileScreen(),
            );
          case AppRoutes.paymentMethods:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const PaymentMethodsScreen(),
            );
        }
        return _errorRoute(settings);
      },
    );
  }

  Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Scaffold(
        body: Center(
          child: Text('Unknown route: ${settings.name}'),
        ),
      ),
    );
  }
}

class _UnauthorizedAccessScreen extends StatelessWidget {
  const _UnauthorizedAccessScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'You do not have permission to access this area.',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.mainShell),
                child: const Text('Return Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
