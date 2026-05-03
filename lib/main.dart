import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'app.dart';
import 'state/app_state.dart';
import 'state/shell_controller.dart';
import 'widgets/error_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ErrorScreen(
          title: 'Firebase Initialization Failed',
          message: 'The app requires a valid Firebase configuration to function. Please check your setup. Details: $e',
        ),
      ),
    );
    return;
  }
  
  final appState = AppState();
  final shell = ShellController();

  // We don't await init here because AppState handles its own loading state
  // which is tracked by the UI in App/SplashScreen.
  appState.init();

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
