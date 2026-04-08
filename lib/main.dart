import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Screens
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/NeuralInitializationScreen.dart';

// Providers
import 'presentation/providers/habit_provider.dart';
import 'presentation/providers/ai_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/hive_provider.dart';

// Core Services
import 'core/services/ai_service.dart';
import 'core/services/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/habit_repository_impl.dart';

void main() async {
  // Ensure Flutter engine is ready for hardware/plugin calls
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Storage & Environment
  // .env must be added to assets in pubspec.yaml
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("NEURAL LINK: Environment Vault loaded successfully.");
  } catch (e) {
    debugPrint(
      "NEURAL ERROR: .env file missing. API functions will be limited.",
    );
  }

  // Initialize Hive and open required boxes
  await Hive.initFlutter();
  final settingsBox = await Hive.openBox('settings');
  await Hive.openBox('habito_box');

  // 2. Initialize Hardware Services
  // Resolves Notification permissions and Timezones internally
  await NotificationService.init();

  // 3. Setup Dependencies
  final String geminiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

  // Fail-safe check for the API key
  if (geminiKey.isEmpty) {
    debugPrint("CRITICAL ALERT: GEMINI_API_KEY not found in environment.");
  }

  final aiService = AIService(geminiKey);
  final habitRepository = HabitRepositoryImpl();

  // Check if this is the Commander's first uplink
  final bool isFirstBoot = settingsBox.get('isFirstBoot', defaultValue: true);

  runApp(
    MultiProvider(
      providers: [
        // HiveProvider handles persona settings and global state
        ChangeNotifierProvider(create: (_) => HiveProvider()),

        // HabitProvider loads the protocols and XP from the local vault
        ChangeNotifierProvider(
          create: (_) =>
              HabitProvider(habitRepository: habitRepository)..loadHabits(),
        ),

        // AIProvider facilitates neural suggestions
        ChangeNotifierProvider(create: (_) => AIProvider(aiService: aiService)),

        // NotificationProvider manages the 4-file scheduling engine
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(aiService: aiService),
        ),
      ],
      child: HabitoApp(isFirstBoot: isFirstBoot),
    ),
  );
}

class HabitoApp extends StatelessWidget {
  final bool isFirstBoot;
  const HabitoApp({super.key, required this.isFirstBoot});

  @override
  Widget build(BuildContext context) {
    // We wrap the app in a Consumer if we need to react to global theme
    // or locale changes from HiveProvider in the future.
    return MaterialApp(
      title: 'Habito AI',
      debugShowCheckedModeBanner: false,

      // Utilizing the custom Sentient/Cyberpunk dark theme
      theme: HabitoTheme.darkTheme,

      // INITIAL NAVIGATION LOGIC:
      // Splash handles the transition, then routes to Onboarding or Home.
      home: HabitoSplashScreen(
        nextScreen: isFirstBoot
            ? const NeuralInitializationScreen()
            : const HomeScreen(),
      ),

      // Global named routes for simplified navigation from notifications
      routes: {
        '/home': (context) => const HomeScreen(),
        '/initialization': (context) => const NeuralInitializationScreen(),
      },
    );
  }
}
