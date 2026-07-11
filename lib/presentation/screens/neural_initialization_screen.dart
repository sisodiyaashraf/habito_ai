import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:do_not_disturb/do_not_disturb.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'home_screen.dart';

class NeuralInitializationScreen extends StatefulWidget {
  const NeuralInitializationScreen({super.key});

  @override
  State<NeuralInitializationScreen> createState() =>
      _NeuralInitializationScreenState();
}

class _NeuralInitializationScreenState extends State<NeuralInitializationScreen>
    with WidgetsBindingObserver {
  final _dndPlugin = DoNotDisturbPlugin();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isNotificationsDone = false;
  bool _isDndDone = false;
  bool _isAlarmDone = false;
  bool _isBootDone = false;
  bool _isInitializing = false;
  double _loadProgress = 0.0;
  String _consoleLog = "AWAITING COMMAND...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isInitializing) {
      _recalibratePermissions();
    }
  }

  Future<void> _recalibratePermissions() async {
    bool isDndAllowed = await _dndPlugin.isNotificationPolicyAccessGranted();

    bool canScheduleAlarms = true;
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      canScheduleAlarms =
          await androidPlugin?.canScheduleExactNotifications() ?? true;
    }

    setState(() {
      _isDndDone = isDndAllowed;
      _isAlarmDone = canScheduleAlarms;

      if (_isDndDone && _isAlarmDone && _isNotificationsDone) {
        _finalizeBoot();
      } else {
        _consoleLog = "SYNC_PARTIAL: HARDWARE MISMATCH DETECTED";
      }
    });
  }

  Future<void> _initializeSystem() async {
    setState(() {
      _isInitializing = true;
      _consoleLog = "SCANNING HARDWARE PROTOCOLS...";
      _loadProgress = 0.1;
    });
    HapticFeedback.mediumImpact();

    // 1. Notifications
    final status = await Permission.notification.request();
    _isNotificationsDone = status.isGranted;

    if (!status.isGranted) {
      _showPermissionError(
        "NOTIFICATION_LINK_FAILED",
        "System cannot push neural updates without permission.",
      );
      return;
    }

    // 2. Exact Alarms
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      bool? canSchedule = await androidPlugin?.canScheduleExactNotifications();

      if (canSchedule == false) {
        _showPermissionError(
          "CLOCK_SYNC_ERROR",
          "Exact Alarms are required for precise habit synchronization.",
        );
        await Future.delayed(const Duration(seconds: 2));
        const intent = AndroidIntent(
          action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
          data: 'package:com.mohdashraf.habito_ai',
        );
        await intent.launch();
        return;
      }
      _isAlarmDone = true;
    }

    // 3. DND / Ghost Mode
    bool isDndAllowed = await _dndPlugin.isNotificationPolicyAccessGranted();
    if (!isDndAllowed) {
      _showPermissionError(
        "GHOST_MODE_OFFLINE",
        "Notification Policy access is mandatory for stealth protocols.",
      );
      await Future.delayed(const Duration(seconds: 2));
      await _dndPlugin.openNotificationPolicyAccessSettings();
    } else {
      _isDndDone = true;
      _finalizeBoot();
    }
  }

  void _showPermissionError(String code, String message) {
    setState(() {
      _consoleLog = "CRITICAL_ERROR: $code";
      _loadProgress = 0.1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              code,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finalizeBoot() async {
    if (_isBootDone) return;
    setState(() {
      _consoleLog = "ESTABLISHING NEURAL SYNC...";
      _loadProgress = 0.9;
    });
    for (int i = 0; i < 5; i++) {
      await Future.delayed(Duration(milliseconds: 100 - (i * 10)));
      HapticFeedback.lightImpact();
    }
    setState(() {
      _consoleLog = "SYNC_COMPLETE: SENTINEL VERIFIED";
      _loadProgress = 1.0;
      _isBootDone = true;
    });
    HapticFeedback.heavyImpact();

    // PERSISTENCE FIX: Mark onboarding as complete in the local vault
    final box = await Hive.openBox('settings');
    await box.put('isFirstBoot', false);

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 1000),
          pageBuilder: (context, anim, secondAnim) => const HomeScreen(),
          transitionsBuilder: (context, anim, secondAnim, child) {
            return FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.1, end: 1.0).animate(anim),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textColor = isLight ? Colors.black87 : theme.colorScheme.onSurface;
    final variantColor = isLight ? Colors.black54 : theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildAmbientGlow(theme),
          _buildScanningLines(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    child: Text(
                      "CORE INITIALIZATION",
                      style: TextStyle(
                        color: theme.colorScheme.primary.withOpacity(0.9),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        fontSize: 22,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      "Hardware sync required. Grant permissions to establish the Neural Link.",
                      style: TextStyle(
                        color: variantColor,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),

                  Center(
                    child: Container(
                      height: 250,
                      width: 250,
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      child: _isInitializing || _isBootDone
                          ? Lottie.asset(
                              'assets/lottie_animation/Bike Loading Animation.json',
                              fit: BoxFit.contain,
                              repeat: true,
                            )
                          : Icon(
                              Icons.directions_bike_rounded,
                              size: 80,
                              color: theme.colorScheme.outline.withOpacity(0.5),
                            ),
                    ),
                  ),

                  _buildProgressBar(theme, textColor, variantColor),
                  const SizedBox(height: 40),
                  _buildStatusLine(
                    "UPLINK: NOTIFICATIONS",
                    _isNotificationsDone,
                    theme,
                    textColor,
                    variantColor,
                  ),
                  _buildStatusLine("HARDWARE: EXACT_ALARM", _isAlarmDone, theme, textColor, variantColor),
                  _buildStatusLine("PROTOCOL: GHOST_MODE", _isDndDone, theme, textColor, variantColor),

                  const SizedBox(height: 30),
                  if (!_isBootDone) Center(child: _buildInitializationButton(theme)),
                  const SizedBox(height: 40),
                  _buildConsole(theme, textColor),
                ],
              ),
            ),
          ),
          if (_isBootDone)
            FadeIn(
              duration: const Duration(milliseconds: 300),
              child: Container(color: theme.colorScheme.primary.withOpacity(0.1)),
            ),
        ],
      ),
    );
  }

  // --- REUSED UI HELPERS ---
  Widget _buildProgressBar(ThemeData theme, Color textColor, Color variantColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "SYNC STATUS",
              style: TextStyle(
                color: variantColor,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
            Text(
              "${(_loadProgress * 100).toInt()}%",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _loadProgress,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitializationButton(ThemeData theme) {
    return FadeInUp(
      child: GestureDetector(
        onTap: _isInitializing ? null : _initializeSystem,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: _isInitializing
                  ? [theme.colorScheme.surface, theme.colorScheme.surface]
                  : [
                      theme.colorScheme.primary.withOpacity(0.3),
                      theme.colorScheme.primary.withOpacity(0.05),
                    ],
            ),
            border: Border.all(
              color: _isInitializing ? theme.colorScheme.outline : theme.colorScheme.primary,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              _isInitializing ? "SYNCHRONIZING..." : "START INITIALIZATION",
              style: TextStyle(
                color: _isInitializing ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 4,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusLine(String label, bool isDone, ThemeData theme, Color textColor, Color variantColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? theme.colorScheme.primary : Colors.transparent,
              border: Border.all(
                color: isDone ? theme.colorScheme.primary : theme.colorScheme.outline,
                width: 2,
              ),
            ),
            child: isDone
                ? Icon(Icons.check, color: theme.colorScheme.onPrimary, size: 12)
                : null,
          ),
          const SizedBox(width: 25),
          Text(
            label,
            style: TextStyle(
              color: isDone ? textColor : variantColor,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsole(ThemeData theme, Color textColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.5),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Text(
              ">",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontFamily: 'monospace',
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                _consoleLog,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningLines() => IgnorePointer(
    child: Opacity(
      opacity: 0.1,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              "https://www.transparenttextures.com/patterns/carbon-fibre.png",
            ),
            repeat: ImageRepeat.repeat,
          ),
        ),
      ),
    ),
  );
  Widget _buildAmbientGlow(ThemeData theme) => Positioned(
    top: -100,
    left: -100,
    child: Container(
      width: 500,
      height: 500,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.07),
            blurRadius: 200,
            spreadRadius: 100,
          ),
        ],
      ),
    ),
  );
}
