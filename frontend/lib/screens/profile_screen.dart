import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../theme/gradient_background.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/sync_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final current = UserService.getCurrent();
    if (current != null) {
      _nameController.text = current.name;
      _emailController.text = current.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = UserService.getCurrent();
    final user = User(
      id: current?.id ?? Uuid().v4(),
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      auth0Id: current?.auth0Id,
      createdAt: current?.createdAt ?? DateTime.now(),
      hasCompletedOnboarding: true,
    );
    UserService.setCurrent(user);
    await SyncService.syncUser(user);
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
