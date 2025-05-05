import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'services/storage_service.dart';
import 'providers/harvest_provider.dart';
import 'screens/home_screen.dart';
import 'widgets/app_message.dart';

void main() {
  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };

  // Catch async errors that aren't caught by the Flutter framework
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      try {
        await StorageService.init();
        runApp(const MyApp());
      } catch (e, stackTrace) {
        debugPrint('Error initializing app: $e');
        debugPrintStack(stackTrace: stackTrace);
        runApp(ErrorApp(error: e.toString()));
      }
    },
    (error, stack) {
      debugPrint('Uncaught exception: $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => HarvestProvider(StorageService()),
      child: MaterialApp(
        title: 'Thiện Tính Cân Lúa',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.yellow.shade600,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}

// Simple error screen to display if initialization fails
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thiện Tính Cân Lúa',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: AppMessage(
          isError: true,
          message:
              'Failed to initialize the app:\n$error\n\nPlease restart the app or contact support if the issue persists.',
        ),
      ),
    );
  }
}
