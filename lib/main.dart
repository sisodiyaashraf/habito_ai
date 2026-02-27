import 'dart:io';
import 'package:flutter/material.dart';
import 'package:habito_ai/presentation/screens/NeuralInitializationScreen.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Screens
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/home_screen.dart';

// Providers
import 'presentation/providers/habit_provider.dart';
import 'presentation/providers/ai_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/hive_provider.dart';

// Core Services
import 'core/services/ai_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/habit_repository_impl.dart';

void main() async {
  // Ensure Flutter engine is ready for hardware/plugin calls
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Storage & Environment
  // Error handling added for .env to prevent crash if key is missing
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint(
      "NEURAL ERROR: .env file missing. API functions will be limited.",
    );
  }

  await Hive.initFlutter();
  var settingsBox = await Hive.openBox('settings');
  await Hive.openBox('habito_box');

  // 2. Initialize Hardware Services
  await NotificationService.init();

  // --- ANDROID 14+ SECURITY PROTOCOL ---
  // Requesting exact alarm permission to ensure Nudges fire at precise times
  if (Platform.isAndroid) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // This checks and requests the permission required for schedulePersonaSmartNudges
    await androidImplementation?.requestExactAlarmsPermission();
  }

  // 3. Setup Dependencies
  final String geminiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
  final aiService = AIService(geminiKey);
  final habitRepository = HabitRepositoryImpl();

  // Check if this is the Commander's first uplink
  final bool isFirstBoot = settingsBox.get('isFirstBoot', defaultValue: true);

  runApp(
    MultiProvider(
      providers: [
        // HiveProvider should be first as others may depend on user settings
        ChangeNotifierProvider(create: (_) => HiveProvider()),

        ChangeNotifierProvider(
          create: (_) =>
              HabitProvider(habitRepository: habitRepository)..loadHabits(),
        ),

        ChangeNotifierProvider(create: (_) => AIProvider(aiService: aiService)),

        // Pass the already created aiService to NotificationProvider for consistency
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
    return MaterialApp(
      title: 'Habito AI',
      debugShowCheckedModeBanner: false,

      // Using your custom Sentient/Cyberpunk theme
      theme: HabitoTheme.darkTheme,

      // Logic:
      // 1. Splash Screen handles the visual transition.
      // 2. Navigates to Initialization (First Boot) or the main Home Hub.
      home: HabitoSplashScreen(
        nextScreen: isFirstBoot
            ? const NeuralInitializationScreen()
            : const HomeScreen(),
      ),

      // Define global routes if needed for notification navigation
      routes: {'/home': (context) => const HomeScreen()},
    );
  }
}
