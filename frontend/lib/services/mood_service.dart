import 'package:hive_flutter/hive_flutter.dart';
import '../models/mood.dart';

class MoodService {
  static const String _boxName = 'moods';
  static Box<Mood>? _box;

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(MoodAdapter());
    }
    _box = await Hive.openBox<Mood>(_boxName);
  }

  static Box<Mood> get _openBox {
    if (_box == null || !_box!.isOpen) {
      throw Exception('MoodService not initialized. Call init() first.');
    }
    return _box!;
  }

  static Future<void> saveMood(DateTime date, int moodLevel) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final key = _dateKey(normalizedDate);
    final mood = Mood(date: normalizedDate, moodLevel: moodLevel);
    await _openBox.put(key, mood);
  }

  static Mood? getMood(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final key = _dateKey(normalizedDate);
    return _openBox.get(key);
  }

  static bool hasLoggedToday() {
    final today = DateTime.now();
    final mood = getMood(today);
    return mood != null;
  }

  static List<Mood> getAll() {
    return _openBox.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<Mood> getMoodsForYear(int year) {
    final allMoods = _openBox.values.toList();
    final filtered = allMoods.where((mood) => mood.date.toLocal().year == year).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return filtered;
  }

  static Map<int, int> getMoodCountsForYear(int year) {
    final moods = getMoodsForYear(year);
    final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final mood in moods) {
      counts[mood.moodLevel] = (counts[mood.moodLevel] ?? 0) + 1;
    }
    return counts;
  }

  static Future<void> deleteMood(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final key = _dateKey(normalizedDate);
    await _openBox.delete(key);
  }

  static Future<void> clearAll() async {
    await _openBox.clear();
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
