import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/sync_service.dart';
import '../services/api_service.dart';
import '../theme/gradient_background.dart';

class CallbackScreen extends StatefulWidget {
  const CallbackScreen({super.key});

  @override
  State<CallbackScreen> createState() => _CallbackScreenState();
}

class _CallbackScreenState extends State<CallbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleCallback();
    });
  }

  Future<void> _handleCallback() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.handleCallback();
      
      final token = await authService.tokenStorage.getAccessToken();
      
      final auth0User = await authService.getUserInfo();
      final auth0Id = auth0User?['sub'];
      
      if (token != null) {
        final apiService = ApiService(backendBaseUrl: 'http://localhost:3001');
        SyncService.initialize(apiService);
      }
      
      await SyncService.pullFromServer();
      
      final currentUser = UserService.getCurrent();
      
      final isReturningUser = currentUser != null && 
                              currentUser.hasCompletedOnboarding;
      
      if (mounted) {
        if (isReturningUser) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/user-info');
        }
      }
    } catch (e) {
      print('Callback error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed: $e')),
        );
        Navigator.of(context).pushReplacementNamed('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Completing sign in...',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
