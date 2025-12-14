import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/user_info_screen.dart';
import 'screens/goals_setup_screen.dart';
import 'screens/tutorial_screen.dart';
import 'screens/home_screen.dart';
import 'screens/journal_entry_screen.dart';
import 'screens/past_entries_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SelfUpgrade',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/user-info': (context) => const UserInfoScreen(),
        '/goals-setup': (context) => const GoalsSetupScreen(),
        '/tutorial': (context) => const TutorialScreen(),
        '/home': (context) => const HomeScreen(),
        '/journal-entry': (context) => const JournalEntryScreen(),
        '/past-entries': (context) => const PastEntriesScreen(),
      },
    );
  }
}
