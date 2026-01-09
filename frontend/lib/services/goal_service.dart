import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/goal.dart';
import 'sync_service.dart';

class GoalService {
  static const String _boxName = 'goals';

  static Box<Goal> get _box => Hive.box<Goal>(_boxName);

  static Future<void> add(Goal goal) async {
    await _box.put(goal.id, goal);
    await SyncService.syncGoal(goal);
  }

  static Future<void> save(Goal goal) async {
    await _box.put(goal.id, goal);
  }

  static Future<void> update(Goal goal) async {
    await _box.put(goal.id, goal);
    await SyncService.updateGoal(goal);
  }

  static List<Goal> getAll() => _box.values.toList();

  static List<Goal> getActive() => _box.values.where((g) => g.isActive).toList();

  static Future<void> delete(String id) async {
    await _box.delete(id);
    await SyncService.deleteGoal(id);
  }

  static ValueListenable<Box<Goal>> listenable() => _box.listenable();
}
