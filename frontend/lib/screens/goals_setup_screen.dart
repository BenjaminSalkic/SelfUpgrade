import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../theme/gradient_background.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';
import '../services/sync_service.dart';
import '../widgets/responsive_container.dart';

class GoalsSetupScreen extends StatefulWidget {
  const GoalsSetupScreen({super.key});

  @override
  State<GoalsSetupScreen> createState() => _GoalsSetupScreenState();
}

class _GoalsSetupScreenState extends State<GoalsSetupScreen> {
  final List<Goal> _goals = [];
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _goals.addAll(GoalService.getAll());
    GoalService.listenable().addListener(() {
      if (mounted) {
        setState(() {
          _goals
            ..clear()
            ..addAll(GoalService.getAll());
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addGoal() {
    if (_titleController.text.isNotEmpty) {
      final goal = Goal(
        id: Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: 'custom',
        createdAt: DateTime.now(),
        isActive: true,
      );
      GoalService.add(goal);
      _titleController.clear();
      _descriptionController.clear();
    }
  }

  void _removeGoal(int index) {
    final id = _goals[index].id;
    GoalService.delete(id);
  }

  Future<void> _continue() async {
    for (final goal in _goals) {
      await SyncService.syncGoal(goal, isNew: true);
    }
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/tutorial');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Your Goals'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ResponsiveContainer(
            maxWidth: 800,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                const Text(
                  'What would you like to track?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add goals you want to achieve. We\'ll prompt you about them when you journal.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Goal (e.g., Exercise daily)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
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
                    onPressed: _addGoal,
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
                const SizedBox(height: 16),
                _goals.isEmpty
                        ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Center(
                        child: Text(
                          'No goals yet. Add your first goal above!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _goals.length,
                        itemBuilder: (context, index) {
                            final goal = _goals[index];
                            return Card(
                              color: const Color(0xFF0A0E12),
                              child: ListTile(
                                title: Text(goal.title, style: const TextStyle(color: Colors.white)),
                                subtitle: goal.description.isNotEmpty
                                    ? Text(goal.description, style: const TextStyle(color: Colors.white70))
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _removeGoal(index),
                                ),
                              ),
                            );
                          },
                        ),
                const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                    boxShadow: _goals.isNotEmpty
                            ? const [
                            BoxShadow(
                              color: Color.fromRGBO(78,244,192,0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : const [],
                ),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goals.isNotEmpty ? _continue : null,
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
        ),
      ),
    );
  }
}
