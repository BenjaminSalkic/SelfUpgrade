import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import 'sync_service.dart';

class UserService {
  static const String _boxName = 'users';

  static Box<User> get _box => Hive.box<User>(_boxName);

  static Future<void> add(User user) async {
    await _box.put(user.id, user);
  }

  static User? getById(String id) => _box.get(id);

  static const String _currentKey = 'current';

  static Future<void> setCurrent(User user) async {
    await _box.put(_currentKey, user);
  }

  static Future<void> saveCurrent(User user) async {
    await _box.put(_currentKey, user);
    await SyncService.syncUser(user);
  }

  static User? getCurrent() => _box.get(_currentKey);

  static Future<void> deleteCurrent() async => await _box.delete(_currentKey);

  static List<User> getAll() => _box.values.toList();

  static Future<void> delete(String id) async => await _box.delete(id);

  static ValueListenable<Box<User>> listenable() => _box.listenable();
}
