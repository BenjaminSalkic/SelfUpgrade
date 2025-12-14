import 'package:flutter/material.dart';
import '../theme/gradient_background.dart';

class GoalsSetupScreen extends StatefulWidget {
  const GoalsSetupScreen({super.key});

  @override
  State<GoalsSetupScreen> createState() => _GoalsSetupScreenState();
}

class _GoalsSetupScreenState extends State<GoalsSetupScreen> {
  final List<Map<String, String>> _goals = [];
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addGoal() {
    if (_titleController.text.isNotEmpty) {
      setState(() {
        _goals.add({
          'title': _titleController.text,
          'description': _descriptionController.text,
        });
        _titleController.clear();
        _descriptionController.clear();
      });
    }
  }

  void _removeGoal(int index) {
    setState(() {
      _goals.removeAt(index);
    });
  }

  void _continue() {
    // TODO: Save goals
    Navigator.pushNamed(context, '/tutorial');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Your Goals'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'What would you like to track?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add goals you want to achieve. We\'ll prompt you about them when you journal.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Goal (e.g., Exercise daily)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4EF4C0).withOpacity(0.4),
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
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _goals.isEmpty
                      ? const Center(
                          child: Text(
                            'No goals yet. Add your first goal above!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _goals.length,
                          itemBuilder: (context, index) {
                            final goal = _goals[index];
                            return Card(
                              child: ListTile(
                                title: Text(goal['title']!),
                                subtitle: goal['description']!.isNotEmpty
                                    ? Text(goal['description']!)
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _removeGoal(index),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _goals.isNotEmpty
                      ? [
                          BoxShadow(
                            color: const Color(0xFF4EF4C0).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
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
    );
  }
}
