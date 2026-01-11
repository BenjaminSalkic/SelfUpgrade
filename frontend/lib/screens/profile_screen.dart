import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../theme/gradient_background.dart';
import '../models/user.dart';
import '../models/goal.dart';
import '../services/user_service.dart';
import '../services/goal_service.dart';
import '../services/sync_service.dart';
import '../widgets/responsive_container.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final List<Goal> _goals = [];

  @override
  void initState() {
    super.initState();
    final current = UserService.getCurrent();
    if (current != null) {
      _nameController.text = current.name;
      _emailController.text = current.email;
    }
    _loadGoals();
    GoalService.listenable().addListener(() {
      if (mounted) {
        _loadGoals();
      }
    });
  }

  void _loadGoals() {
    setState(() {
      _goals
        ..clear()
        ..addAll(GoalService.getAll());
    });
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

  void _addOrEditGoal({Goal? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          final isEnabled = titleController.text.trim().isNotEmpty;
          return AlertDialog(
            backgroundColor: const Color(0xFF0A0E12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(existing == null ? 'Add Goal' : 'Edit Goal'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320, minWidth: 300),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(labelText: 'Title'),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 8,
                      minLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isEnabled
                      ? const [
                          BoxShadow(
                            color: Color.fromRGBO(78,244,192,0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: ElevatedButton(
                  onPressed: isEnabled
                      ? () {
                          final goal = Goal(
                            id: existing?.id ?? Uuid().v4(),
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            category: existing?.category ?? 'custom',
                            createdAt: existing?.createdAt ?? DateTime.now(),
                            isActive: true,
                          );
                          if (existing == null) {
                            GoalService.add(goal);
                          } else {
                            GoalService.update(goal);
                          }
                          SyncService.syncGoal(goal, isNew: existing == null);
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('Save'),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  void _deleteGoal(String id) {
    GoalService.delete(id);
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Goals')),
      body: GradientBackground(
        child: SafeArea(
          child: ResponsiveContainer(
            maxWidth: 800,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Info',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4EF4C0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
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
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Info', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your Goals',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4EF4C0),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0E10).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4EF4C0).withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: _goals.isEmpty
                        ? const Center(
                            child: Text(
                              'No goals yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _goals.length,
                            itemBuilder: (context, index) {
                              final g = _goals[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A0E10),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF4EF4C0).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(g.title, style: const TextStyle(color: Colors.white)),
                                  subtitle: g.description.isNotEmpty
                                      ? Text(g.description, style: const TextStyle(color: Colors.white70))
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _addOrEditGoal(existing: g),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _deleteGoal(g.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(78,244,192,0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _addOrEditGoal(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Goal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4EF4C0),
                        foregroundColor: const Color(0xFF0A0E12),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
