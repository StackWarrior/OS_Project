import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../state/app_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkStatus();
  }

  void _checkStatus() {
    final app = context.watch<AppState>();
    
    // Only navigate once we are out of initial/loading states
    if (app.status == AppStatus.loading || app.status == AppStatus.initial) {
      return;
    }

    // Use a small delay to allow animation to show slightly
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      if (app.status == AppStatus.error) {
        // App.dart handles the error screen globally if we return the MaterialApp there,
        // but since SplashScreen is a child of MaterialApp, we might stay here if status is error.
        // Actually, in app.dart I implemented a global check.
        return;
      }

      if (!app.onboardingComplete) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
        return;
      }

      if (app.status == AppStatus.unauthenticated) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        return;
      }

      if (app.status == AppStatus.authenticated) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.mainShell);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primary, scheme.tertiary],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 30,
                          spreadRadius: 2,
                          color: Colors.black.withValues(alpha: 0.18),
                        ),
                      ],
                    ),
                    child: Icon(Icons.auto_stories_rounded, size: 64, color: scheme.primary),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'CourseLab',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Learn. Build. Ship.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                  ),
                  const SizedBox(height: 28),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
