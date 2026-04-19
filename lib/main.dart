// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/diagnostic_controller.dart';
import 'controllers/learning_path_controller.dart';
import 'services/hive_service.dart';
import 'core/data/local_database.dart';
import 'core/database/app_database.dart';
import 'firebase_options.dart';

import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/permissions_screen.dart';
import 'features/auth/presentation/screens/entry_point_screen.dart';
import 'features/diagnostic/presentation/screens/preassess_screen.dart';
import 'features/diagnostic/presentation/screens/brief_screen.dart';
import 'features/diagnostic/presentation/screens/question_screen.dart';
import 'features/diagnostic/presentation/screens/result_screen.dart';
import 'shared/widgets/main_nav_shell.dart';
import 'features/learn/presentation/screens/lesson_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Bypass reCAPTCHA in debug mode
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  // Local storage
  await HiveService.init();
  await AppDatabase.instance.database;
  await LocalDatabase.init();

  // Force portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF14122A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()..init()),
        ChangeNotifierProvider(create: (_) => DiagnosticController()),
        // LearningPathController must be global — ResultScreen accesses it
        // from any navigation path, including post-logout re-login.
        ChangeNotifierProvider(create: (_) => LearningPathController()),
      ],
      child: const MyAdaApp(),
    ),
  );
}

class MyAdaApp extends StatelessWidget {
  const MyAdaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyADA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthGate(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.onboarding:
            return MaterialPageRoute(builder: (_) => const OnboardingScreen());
          case AppRoutes.permissions:
            return MaterialPageRoute(builder: (_) => const PermissionsScreen());
          case AppRoutes.entry:
            return MaterialPageRoute(builder: (_) => const EntryPointScreen());
          case AppRoutes.register:
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case AppRoutes.login:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case AppRoutes.forgotPassword:
            return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
          case AppRoutes.home:
            return MaterialPageRoute(builder: (_) => const MainNavShell());
          case AppRoutes.diagnostic:
            return MaterialPageRoute(builder: (_) => const PreassessScreen());
          case AppRoutes.diagBrief:
            return MaterialPageRoute(builder: (_) => const BriefScreen());
          case AppRoutes.diagQuestion:
            return MaterialPageRoute(builder: (_) => const QuestionScreen());
          case AppRoutes.diagResult:
            return MaterialPageRoute(builder: (_) => const ResultScreen());
          case AppRoutes.lesson:
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => LessonScreen(
                lessonId: args['lessonId'] ?? 'm01_l01',
                moduleId: args['moduleId'] ?? 'module_01',
                lessonNumber: args['lessonNumber'] ?? 1,
                totalLessonsInModule: args['totalLessonsInModule'] ?? 5,
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}

/// Smart gate — reads AuthController and routes accordingly.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _pathLoaded = false;

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthController>();
    final pathCtrl = context.watch<LearningPathController>();

    switch (auth.status) {
      // ── App still initialising — show branded splash ───────────────────────
      case AuthStatus.unknown:
      case AuthStatus.loading:
        return const SplashScreen();

      // ── No valid session ───────────────────────────────────────────────────
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        // Reset path-loaded flag so it reloads on next login.
        if (_pathLoaded) _pathLoaded = false;
        return auth.hasEverLoggedIn
            ? const LoginScreen()
            : const EntryPointScreen();

      // ── Valid session ──────────────────────────────────────────────────────
      case AuthStatus.authenticated:
        final user = auth.currentUser;
        if (user == null || !user.hasCompletedDiagnostic) {
          return const PreassessScreen();
        }

        // Load persisted diagnostic exactly once per authenticated session.
        if (!_pathLoaded && !pathCtrl.hasResult && !pathCtrl.isBuilding) {
          _pathLoaded = true;
          Future.microtask(() => pathCtrl.loadResultFromDb());
        }

        return const MainNavShell();
    }
  }
}

/// Central route name constants.
class AppRoutes {
  // Auth
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const permissions = '/permissions';
  static const entry = '/entry';
  static const register = '/register';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';

  // Main
  static const home = '/home';

  // Diagnostic
  static const diagnostic = '/diagnostic';
  static const diagBrief = '/diagnostic/brief';
  static const diagQuestion = '/diagnostic/question';
  static const diagResult = '/diagnostic/result';

  // Learning
  static const lesson = '/lesson';
  static const learnPath = '/learn/path';
  static const codeEditor = '/learn/code-editor';
  static const quiz = '/learn/quiz';
}
