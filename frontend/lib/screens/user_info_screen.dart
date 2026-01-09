import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../theme/gradient_background.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';


class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _auth0Id;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final auth0User = await authService.getUserInfo();
    
    if (auth0User != null) {
      setState(() {
        _nameController.text = auth0User['name'] ?? '';
        _emailController.text = auth0User['email'] ?? '';
        _auth0Id = auth0User['sub'];
      });
    } else {
      final current = UserService.getCurrent();
      if (current != null) {
        setState(() {
          _nameController.text = current.name;
          _emailController.text = current.email;
        });
      }
    }
  }

  Future<void> _continue() async {
    if (_formKey.currentState!.validate()) {
      final existingUser = UserService.getCurrent();
      
      final user = User(
        id: existingUser?.id ?? Uuid().v4(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        createdAt: existingUser?.createdAt ?? DateTime.now(),
        hasCompletedOnboarding: true,
        auth0Id: _auth0Id,
      );
      UserService.setCurrent(user);
      await SyncService.syncUser(user);
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/goals-setup');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tell us about yourself'),
      ),
      body: GradientBackground(
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Let\'s get to know you',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This helps us personalize your journaling experience',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(78,244,192,0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _continue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Continue', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
