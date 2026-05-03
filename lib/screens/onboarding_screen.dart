import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../state/app_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _index = 0;

  List<_OnboardPageData> _getPages(bool isEn) {
    return [
      _OnboardPageData(
        image: 'assets/icon/1.jpg',
        title: isEn ? 'Explore Clear Learning Paths' : 'استكشف مسارات تعلم واضحة',
        subtitle: isEn 
            ? 'Practical paths that bridge concepts with real-world projects.'
            : 'مسارات عملية تربط المفاهيم بالمشاريع الحقيقية — واجهة جميلة ومريحة للعين.',
        accent: const Color(0xFF6366F1),
      ),
      _OnboardPageData(
        image: 'assets/icon/2.jpg',
        title: isEn ? 'Learn by Watching and Testing' : 'تعلّم بالمشاهدة والاختبار',
        subtitle: isEn
            ? 'Video player with progress tracking and timed quizzes.'
            : 'مشغّل فيديو مع تتبّع التقدّم، واختبارات موقوتة تثبت ما تعلمته.',
        accent: const Color(0xFF0EA5E9),
      ),
      _OnboardPageData(
        image: 'assets/icon/3.jpg',
        title: isEn ? 'Your Progress is Always Saved' : 'تقدّمك محفوظ دائمًا',
        subtitle: isEn
            ? 'Resumption, favorites, and my courses — all in one seamless experience.'
            : 'استئناف التشغيل، المفضلة، ودوراتي — كل شيء متصل بتجربة واحدة سلسة.',
        accent: const Color(0xFF22C55E),
      ),
    ];
  }

  Future<void> _finish() async {
    await context.read<AppState>().completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isEn = app.locale.languageCode == 'en';
    final theme = Theme.of(context);
    final pages = _getPages(isEn);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => app.toggleLanguage(),
                    icon: const Icon(Icons.translate),
                    tooltip: isEn ? 'Switch Language' : 'تغيير اللغة',
                  ),
                  TextButton(
                    onPressed: _finish,
                    child: Text(isEn ? 'Skip' : 'تخطي'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = pages[i];
                  return _OnboardPage(
                    image: p.image,
                    title: p.title,
                    subtitle: p.subtitle,
                    accent: p.accent,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  Row(
                    children: List.generate(
                      pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        height: 8,
                        width: i == _index ? 26 : 8,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (_index < pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        _finish();
                      }
                    },
                    child: Text(_index < pages.length - 1 ? (isEn ? 'Next' : 'التالي') : (isEn ? 'Get started' : 'ابدأ الآن')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPageData {
  final String image;
  final String title;
  final String subtitle;
  final Color accent;

  const _OnboardPageData({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.accent,
  });
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String image;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.15),
                        accent.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 40,
                        spreadRadius: -10,
                        color: accent.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                  child: Image.asset(image, fit: BoxFit.cover ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
