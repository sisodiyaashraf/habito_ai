import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Screens
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/neural_initialization_screen.dart';

// Providers
import 'presentation/providers/habit_provider.dart';
import 'presentation/providers/ai_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/hive_provider.dart';

// Core Services
import 'core/services/ai_service.dart';
import 'core/services/ai_usage_service.dart';
import 'core/services/notifications/notification_service.dart';
import 'core/services/connectivity_service.dart';
import 'data/repositories/habit_repository_impl.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure Flutter engine is ready for hardware/plugin calls
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Connectivity
  final connectivityService = ConnectivityService();
  await connectivityService.init();

  // Initialize AI Usage Tracker
  await Hive.initFlutter();
  final aiUsageService = AIUsageService();
  await aiUsageService.init();

  // 1. Initialize Storage & Environment
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("NEURAL LINK: Environment Vault loaded successfully.");
  } catch (e) {
    debugPrint(
      "NEURAL ERROR: .env file missing. API functions will be limited.",
    );
  }

  // Open required boxes
  final settingsBox = await Hive.openBox('settings');
  await Hive.openBox('habito_box');

  // 2. Initialize Hardware Services
  await NotificationService.init();

  // 3. Setup Dependencies
  final String geminiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  ).isNotEmpty 
      ? const String.fromEnvironment('GEMINI_API_KEY') 
      : (dotenv.env['GEMINI_API_KEY'] ?? "");

  if (geminiKey.isEmpty) {
    debugPrint("CRITICAL ALERT: GEMINI_API_KEY not found in environment or .env.");
  }

  final aiService = AIService(geminiKey, aiUsageService);
  final habitRepository = HabitRepositoryImpl();

  final bool isFirstBoot = settingsBox.get('isFirstBoot', defaultValue: true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HiveProvider()..loadHiveSettings(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              HabitProvider(habitRepository: habitRepository)..loadHabits(),
        ),
        ChangeNotifierProvider(create: (_) => AIProvider(aiService: aiService)),
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
    return Consumer<HiveProvider>(
      builder: (context, hive, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Habito AI',
          debugShowCheckedModeBanner: false,
          theme: HabitoTheme.lightTheme,
          darkTheme: HabitoTheme.darkTheme,
          themeMode: hive.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: HabitoSplashScreen(
            nextScreen: isFirstBoot
                ? const NeuralInitializationScreen()
                : const HomeScreen(),
          ),
          routes: {
            '/home': (context) => const HomeScreen(),
            '/initialization': (context) => const NeuralInitializationScreen(),
          },
        );
      },
    );
  }
}
