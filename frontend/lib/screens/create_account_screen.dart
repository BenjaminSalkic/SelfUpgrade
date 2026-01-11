import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/gradient_background.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/user_service.dart';

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  void _continueToUserInfo(BuildContext context) {
    Navigator.pushNamed(context, '/user-info');
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: Image.asset(
                  'assets/google-icon.png',
                  height: 24,
                  width: 24,
                ),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(220, 48),
                  textStyle: const TextStyle(fontSize: 16),
                  elevation: 2,
                ),
                onPressed: () async {
                  try {
                    final result = await authService.login(scheme: 'com.selfupgrade.app');
                    if (result != null && context.mounted) {
                      // Login successful - initialize sync and pull data
                      if (authService.apiService != null) {
                        SyncService.initialize(authService.apiService!);
                        await SyncService.pullFromServer();
                      }
                      
                      // Check if user has completed onboarding
                      final user = await UserService.getCurrent();
                      
                      if (context.mounted) {
                        if (user != null && user.hasCompletedOnboarding) {
                          // User exists and has completed onboarding - go to home
                          Navigator.of(context).pushReplacementNamed('/home');
                        } else {
                          // New user or incomplete onboarding - start onboarding flow
                          Navigator.of(context).pushReplacementNamed('/user-info');
                        }
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Authentication service is currently unavailable. Please use "Skip" to continue with local storage only.'),
                          duration: Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _continueToUserInfo(context),
                child: const Text('Skip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
