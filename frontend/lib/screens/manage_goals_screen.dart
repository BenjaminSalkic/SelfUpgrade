import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../theme/gradient_background.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';
import '../services/sync_service.dart';
import '../widgets/responsive_container.dart';

class ManageGoalsScreen extends StatefulWidget {
  const ManageGoalsScreen({super.key});

  @override
  State<ManageGoalsScreen> createState() => _ManageGoalsScreenState();
}

class _ManageGoalsScreenState extends State<ManageGoalsScreen> {
  final List<Goal> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
    GoalService.listenable().addListener(() {
      if (mounted) {
        _loadGoals();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadGoals() {
    setState(() {
      _goals
        ..clear()
        ..addAll(GoalService.getAll());
    });
  }

  void _addOrEdit({Goal? existing}) {
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
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            contentTextStyle: const TextStyle(color: Colors.white70),
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
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4EF4C0),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
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
                      : null,
                ),
                child: ElevatedButton(
                  onPressed: isEnabled
                      ? () async {
                          final goal = Goal(
                            id: existing?.id ?? Uuid().v4(),
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            category: 'custom',
                            createdAt: existing?.createdAt ?? DateTime.now(),
                            isActive: existing?.isActive ?? true,
                          );
                          GoalService.add(goal);
                          if (existing == null) {
                            await SyncService.syncGoal(goal);
                          } else {
                            await SyncService.updateGoal(goal);
                          }
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4EF4C0),
                    foregroundColor: const Color(0xFF0A0E12),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  void _delete(String id) {
    GoalService.delete(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: GradientBackground(
        child: SafeArea(
          child: ResponsiveContainer(
            maxWidth: 800,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: _goals.isEmpty
                      ? const Center(child: Text('No goals yet'))
                      : ListView.builder(
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
                                subtitle: g.description.isNotEmpty ? Text(g.description, style: const TextStyle(color: Colors.white70)) : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _addOrEdit(existing: g)),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _delete(g.id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
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
                    onPressed: () => _addOrEdit(),
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
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
