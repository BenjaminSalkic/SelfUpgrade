import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'config.dart';
import 'services/auth_service_web.dart' if (dart.library.io) 'services/auth_service_stub.dart';
import 'services/mood_service.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'models/adapters/journal_entry_adapter.dart';
import 'models/adapters/goal_adapter.dart';
import 'models/adapters/user_adapter.dart';
import 'models/mood.dart';
import 'models/journal_entry.dart';
import 'models/goal.dart';
import 'models/user.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/user_info_screen.dart';
import 'screens/create_account_screen.dart';
import 'screens/goals_setup_screen.dart';
import 'screens/tutorial_screen.dart';
import 'screens/home_screen.dart';
import 'screens/journal_entry_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/manage_goals_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/callback_screen.dart';
import 'screens/clear_data_screen.dart';
import 'screens/debug_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    saveHashOnStartup();
  }
  
  await Hive.initFlutter();
  Hive.registerAdapter(JournalEntryAdapter());
  Hive.registerAdapter(GoalAdapter());
  Hive.registerAdapter(UserAdapter());
  await Hive.openBox<JournalEntry>('journal_entries');
  await Hive.openBox<Goal>('goals');
  await Hive.openBox<User>('users');
  await MoodService.init();
  
  if (!kIsWeb) {
    await NotificationService.initialize();
    await NotificationService.requestPermissions();
    await NotificationService.scheduleAll();
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (_) {
        final svc = AuthService(backendBaseUrl: kBackendBaseUrl);
        svc.loadConfig().then((_) async {
          if (svc.apiService != null) {
            SyncService.initialize(svc.apiService!);
            await SyncService.pullFromServer();
          }
        }).catchError((e) {
          print('Warning: Could not connect to backend at $kBackendBaseUrl');
          print('Auth features will be unavailable until backend is running.');
        });
        return svc;
      },
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SelfUpgrade',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const InitialRouteResolver(),
      routes: {
        '/callback': (context) => const CallbackScreen(),
        '/create-account': (context) => const CreateAccountScreen(),
        '/user-info': (context) => const UserInfoScreen(),
        '/goals-setup': (context) => const GoalsSetupScreen(),
        '/tutorial': (context) => const TutorialScreen(),
        '/home': (context) => const HomeScreen(),
        '/journal-entry': (context) => const JournalEntryScreen(),
        '/past-entries': (context) => const ProgressScreen(),
        '/stats': (context) => const StatsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/manage-goals': (context) => const ManageGoalsScreen(),
        '/notification-settings': (context) => const NotificationSettingsScreen(),
        '/clear-data': (context) => const ClearDataScreen(),
        '/debug': (context) => const DebugScreen(),
      },
    );
  }
}

class InitialRouteResolver extends StatefulWidget {
  const InitialRouteResolver({super.key});

  @override
  State<InitialRouteResolver> createState() => _InitialRouteResolverState();
}

class _InitialRouteResolverState extends State<InitialRouteResolver> {
  bool _isInitializing = true;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _initializeAndCheckToken();
  }

  Future<void> _initializeAndCheckToken() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Check for token
    final token = await authService.tokenStorage.getAccessToken();

    if (token != null) {
      // Ensure auth config is loaded and SyncService is initialized
      try {
        await authService.loadConfig();
        if (authService.apiService != null) {
          SyncService.initialize(authService.apiService!);
          // Pull from server in background - don't block navigation
          SyncService.pullFromServer();
        }
      } catch (e) {
        print('Warning: Could not initialize sync service: $e');
      }

      if (mounted) {
        setState(() {
          _hasToken = true;
          _isInitializing = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _hasToken = false;
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && getLocationPathname().contains('callback')) {
      return const CallbackScreen();
    }

    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/home');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return const WelcomeScreen();
  }
}
