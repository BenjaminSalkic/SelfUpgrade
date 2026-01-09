import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/token_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ClearDataScreen extends StatelessWidget {
  const ClearDataScreen({super.key});

  Future<void> _clearAllData(BuildContext context) async {
    try {
      await TokenStorage().clear();
      
      final journalBox = await Hive.openBox('journal_entries');
      await journalBox.clear();
      
      final goalsBox = await Hive.openBox('goals');
      await goalsBox.clear();
      
      final usersBox = await Hive.openBox('users');
      await usersBox.clear();
      
      if (kIsWeb) {
        await Hive.deleteFromDisk();
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared! Please reload the app.')),
        );
        
        await Future.delayed(const Duration(seconds: 2));
        
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Clear All Data'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                'Clear All Data',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                'This will delete:\n• Auth tokens\n• Journal entries\n• Goals\n• User data\n\nYou will need to log in again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _clearAllData(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text('Clear Everything', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
