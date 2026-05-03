import '../models/course.dart';
import '../models/quiz_question.dart';

/// Sample stream URL (Big Buck Bunny) — works for demo playback.
const String kDemoVideoUrl =
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

List<Course> buildSeedCourses() {
  String thumb(int n) =>
      'https://picsum.photos/seed/course$n/800/480';

  QuizQuestion q(String id, String prompt, List<String> opts, int correct) =>
      QuizQuestion(id: id, prompt: prompt, options: opts, correctIndex: correct);

  return [
    Course(
      id: 'c1',
      title: 'Flutter UI Mastery',
      description:
          'Build polished mobile layouts with Material 3, responsive design, and animation patterns used in production apps.',
      category: 'Mobile',
      price: 49.99,
      thumbnailUrl: thumb(1),
      videoUrl: kDemoVideoUrl,
      durationMinutes: 320,
      featured: true,
      quiz: [
        q('c1q1', 'Which widget is best for scrollable lists of uniform height?',
            ['Column', 'ListView', 'Stack', 'Table'], 1),
        q('c1q2', 'What does `const` on a widget constructor enable?',
            ['Hot reload only', 'Compile-time instantiation & fewer rebuilds', 'Networking', 'Persistence'],
            1),
        q('c1q3', 'ThemeData is typically provided by:',
            ['Navigator', 'MaterialApp / Theme', 'HttpClient', 'Isolate'], 1),
      ],
    ),
    Course(
      id: 'c2',
      title: 'Dart for App Developers',
      description:
          'Async/await, isolates, null safety, and patterns for maintainable Dart codebases.',
      category: 'Programming',
      price: 39.0,
      thumbnailUrl: thumb(2),
      videoUrl: kDemoVideoUrl,
      durationMinutes: 240,
      featured: true,
      quiz: [
        q('c2q1', '`Future` represents:',
            ['A past value', 'A value or error arriving later', 'A UI route', 'A database row'], 1),
        q('c2q2', 'Sound null safety helps prevent:',
            ['Build failures', 'Null reference errors at runtime', 'Slow animations', 'Large APK size'],
            1),
      ],
    ),
    Course(
      id: 'c3',
      title: 'State Management Blueprint',
      description:
          'Compare Provider, Riverpod, and Bloc with hands-on exercises and decision frameworks.',
      category: 'Architecture',
      price: 59.5,
      thumbnailUrl: thumb(3),
      videoUrl: kDemoVideoUrl,
      durationMinutes: 410,
      featured: false,
      quiz: [
        q('c3q1', 'ChangeNotifier is typically paired with:',
            ['setState only', 'ListView only', 'Provider / listenables', 'ShaderMask'], 2),
        q('c3q2', 'A key benefit of unidirectional data flow is:',
            ['Smaller fonts', 'Easier reasoning about updates', 'No need for widgets', 'Faster GPS'],
            1),
        q('c3q3', 'Ephemeral UI state often lives in:',
            ['A StatefulWidget', 'Only databases', 'Gradle files', 'CI YAML'], 0),
      ],
    ),
    Course(
      id: 'c4',
      title: 'REST APIs & JSON in Flutter',
      description:
          'Model serialization, error handling, caching, and testing networked features.',
      category: 'Backend',
      price: 44.0,
      thumbnailUrl: thumb(4),
      videoUrl: kDemoVideoUrl,
      durationMinutes: 280,
      featured: false,
      quiz: [
        q('c4q1', 'HTTP 404 means:',
            ['Created', 'Unauthorized', 'Not Found', 'Rate limited'], 2),
        q('c4q2', 'Idempotent methods often include:',
            ['POST for payments', 'GET and PUT (in many designs)', 'CONNECT only', 'TRACE only'], 1),
      ],
    ),
    Course(
      id: 'c5',
      title: 'Product Design for Devs',
      description:
          'Typography, spacing, accessibility (a11y), and motion — from Figma to Flutter widgets.',
      category: 'Design',
      price: 35.0,
      thumbnailUrl: thumb(5),
      videoUrl: kDemoVideoUrl,
      durationMinutes: 190,
      featured: true,
      quiz: [
        q('c5q1', 'WCAG contrast guidance primarily helps:',
            ['Battery life', 'Users with low vision', 'APK size', 'GPS accuracy'], 1),
        q('c5q2', '8pt spacing grids help:',
            ['Random layouts', 'Consistent rhythm & alignment', 'Shader compilation', 'Keystore'], 1),
      ],
    ),
    Course(
      id: 'c6',
      title: 'Testing Flutter Apps',
      description:
          'Unit, widget, and integration tests with golden rules and CI-friendly setups.',
      category: 'Quality',
      price: 42.25,
      thumbnailUrl: thumb(6),
      videoUrl: kDemoVideoUrl,
      durationMinutes: 300,
      featured: false,
      quiz: [
        q('c6q1', '`testWidgets` is used for:',
            ['Kernel modules', 'Widget tests', 'Signing bundles', 'Shader warm-up'], 1),
        q('c6q2', 'A good first test target is:',
            ['Pure functions / models', 'Only splash GIFs', 'Gradle sync', 'Xcode indexing'], 0),
      ],
    ),
    Course(
      id: 'c7',
      title: 'Performance Tuning',
      description:
          'Profiling with DevTools: jank, shaders, images, and build/layout/paint tradeoffs.',
      category: 'Mobile',
      price: 55.0,
      thumbnailUrl: thumb(7),
      videoUrl: kDemoVideoUrl,
      durationMinutes: 220,
      featured: false,
      quiz: [
        q('c7q1', 'The Performance overlay helps spot:',
            ['Wi-Fi SSID', 'Frame budget issues', 'Disk encryption', 'SIM carrier'], 1),
        q('c7q2', '`RepaintBoundary` can reduce:',
            ['Network usage', 'Unnecessary repaint regions', 'Gradle daemon memory', 'DNS lookups'], 1),
      ],
    ),
    Course(
      id: 'c8',
      title: 'Shipping to Stores',
      description:
          'Play Console & App Store Connect essentials: signing, versioning, and staged rollouts.',
      category: 'DevOps',
      price: 29.99,
      thumbnailUrl: thumb(8),
      videoUrl: kDemoVideoUrl,
      durationMinutes: 150,
      featured: false,
      quiz: [
        q('c8q1', 'AAB is primarily used for:',
            ['iOS installs', 'Google Play uploads', 'Desktop MSIX', 'Docker images'], 1),
        q('c8q2', 'Semantic versioning is typically:',
            ['major.minor.patch', 'random strings', 'RGB tuples', 'latitude/longitude'], 0),
      ],
    ),
    Course(
      id: 'c9',
      title: 'Full-Stack Web with Flutter',
      description:
          'Learn to build responsive, SEO-friendly web applications using Flutter for Web and a Node.js backend.',
      category: 'Web',
      price: 49.99,
      thumbnailUrl: thumb(9),
      videoUrl: kDemoVideoUrl,
      durationMinutes: 450,
      featured: true,
      quiz: [
        q('c9q1', 'Which package is often used for routing in Flutter Web?',
            ['go_router', 'http', 'provider', 'path_provider'], 0),
        q('c9q2', 'Can Flutter Web apps be served as static files?',
            ['No', 'Only on Firebase', 'Yes', 'Only on Android'], 2),
      ],
    ),
    Course(
      id: 'c10',
      title: 'AI & Machine Learning for Devs',
      description:
          'Integrate OpenAI, TensorFlow Lite, and Computer Vision into your mobile apps with hands-on projects.',
      category: 'AI',
      price: 69.99,
      thumbnailUrl: thumb(10),
      videoUrl: kDemoVideoUrl,
      durationMinutes: 520,
      featured: true,
      quiz: [
        q('c10q1', 'What does LLM stand for?',
            ['Large Language Model', 'Linear Line Matrix', 'Local Logic Module', 'Low Level Memory'], 0),
        q('c10q2', 'TensorFlow Lite is optimized for:',
            ['Supercomputers', 'Web Browsers only', 'Mobile and Embedded devices', 'Windows Server'], 2),
      ],
    ),
    Course(
      id: 'c11',
      title: 'Firebase for Production',
      description:
          'Master Cloud Functions, Security Rules, and Advanced Querying for scalable app backends.',
      category: 'Cloud',
      price: 45.0,
      thumbnailUrl: thumb(11),
      videoUrl: kDemoVideoUrl,
      durationMinutes: 380,
      featured: false,
      quiz: [
        q('c11q1', 'Where do Security Rules run?',
            ['On the client device', 'In the Firebase backend', 'On a proxy server', 'In the developer console'], 1),
        q('c11q2', 'Cloud Functions are written in:',
            ['Dart', 'Swift', 'JavaScript/TypeScript', 'C++'], 2),
      ],
    ),
    Course(
      id: 'c12',
      title: 'Advanced Animation Workshop',
      description:
          'From simple tweens to complex particle systems and physics-based motion in Flutter.',
      category: 'Design',
      price: 55.0,
      thumbnailUrl: thumb(12),
      videoUrl: kDemoVideoUrl,
      durationMinutes: 280,
      featured: false,
      quiz: [
        q('c12q1', 'Which widget is best for explicit animations?',
            ['AnimatedContainer', 'AnimatedBuilder', 'Container', 'SizedBox'], 1),
        q('c12q2', 'What provides the ticking for animations?',
            ['Timer', 'Stream', 'TickerProvider / vsync', 'Future'], 2),
      ],
    ),
  ];
}
