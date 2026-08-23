import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_language_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/dashboard_provider.dart';
import 'core/providers/course_provider.dart';
import 'core/providers/knowledge_hub_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/specialist_provider.dart';
import 'core/services/auth_service.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase initialization skipped or already initialized: $e');
  }
  runApp(const AshwashApp());
}

class AshwashApp extends StatelessWidget {
  const AshwashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppLanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => KnowledgeHubProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SpecialistProvider()),
        Provider(create: (_) => AuthService()),
      ],
      child: Consumer2<AppThemeProvider, AppLanguageProvider>(
        builder: (context, themeProvider, langProvider, child) {
          return MaterialApp(
            title: 'Ashwash (আশ্বাস)',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppThemeProvider.lightTheme,
            darkTheme: AppThemeProvider.darkTheme,
            builder: (context, child) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFB388FF),
                      Color(0xFFA18FFF),
                      Color(0xFFB7F1E3),
                    ],
                  ),
                ),
                child: child,
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}


