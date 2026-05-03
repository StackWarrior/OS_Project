import 'package:course_learning_app/app.dart';
import 'package:course_learning_app/state/app_state.dart';
import 'package:course_learning_app/state/shell_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App builds with providers', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    await appState.init();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          ChangeNotifierProvider<ShellController>.value(
            value: ShellController(),
          ),
        ],
        child: const CourseLearningApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
