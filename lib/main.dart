import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/service_locator.dart';
import 'features/editor/editor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ServiceLocator - this connects web services to the backend
  try {
    await ServiceLocator.instance.initialize();
    debugPrint('ServiceLocator initialized successfully');
  } catch (e) {
    debugPrint('ServiceLocator initialization failed: $e');
    // Continue anyway - the app will show connection error state
  }

  runApp(const VisualAppBuilderApp());
}

class VisualAppBuilderApp extends StatelessWidget {
  const VisualAppBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Visual App Builder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const EditorScreen(),
    ),
  ],
);
