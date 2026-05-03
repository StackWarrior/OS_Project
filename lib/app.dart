import 'package:flutter/material.dart';

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
import 'theme/app_theme.dart';

class CourseLearningApp extends StatelessWidget {
  const CourseLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CourseLab',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
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
            final id = settings.arguments as String;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => CourseDetailScreen(courseId: id),
            );
          case AppRoutes.videoPlayer:
            final id = settings.arguments as String;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => VideoPlayerScreen(courseId: id),
            );
          case AppRoutes.quiz:
            final id = settings.arguments as String;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => QuizScreen(courseId: id),
            );
          case AppRoutes.quizResult:
            final result = settings.arguments as QuizSessionResult;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => QuizResultScreen(result: result),
            );
          case AppRoutes.checkout:
            final id = settings.arguments as String;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => CheckoutScreen(courseId: id),
            );
          case AppRoutes.admin:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const AdminDashboardScreen(),
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
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Unknown route: ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}
