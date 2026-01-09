import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
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
        final svc = AuthService(backendBaseUrl: 'http://localhost:3001');
        svc.loadConfig().then((_) async {
          if (svc.apiService != null) {
            SyncService.initialize(svc.apiService!);
            await SyncService.pullFromServer();
          }
        }).catchError((e) {
          print('Warning: Could not connect to backend at http://localhost:3001');
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

class InitialRouteResolver extends StatelessWidget {
  const InitialRouteResolver({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && getLocationPathname().contains('callback')) {
      return const CallbackScreen();
    }
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return FutureBuilder<String?>(
      future: authService.tokenStorage.getAccessToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/home');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        return const WelcomeScreen();
      },
    );
  }
}
