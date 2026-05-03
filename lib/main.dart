import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'app.dart';
import 'state/app_state.dart';
import 'state/shell_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;
  try {
    // Attempt to initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    debugPrint('Firebase initialized successfully.');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('Continuing in Demo Mode without Firebase services.');
  }
  
  final appState = AppState();
  // Initialize AppState with the Firebase status
  await appState.init(isFirebaseAvailable: firebaseInitialized);
  
  final shell = ShellController();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<ShellController>.value(value: shell),
      ],
      child: const CourseLearningApp(),
    ),
  );
}
