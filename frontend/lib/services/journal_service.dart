import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/journal_entry.dart';
import 'sync_service.dart';

class JournalService {
  static const String _boxName = 'journal_entries';

  static Box<JournalEntry> get _box => Hive.box<JournalEntry>(_boxName);

  static Future<void> add(JournalEntry entry) async {
    await _box.put(entry.id, entry);
    await SyncService.syncJournalEntry(entry);
  }

  static Future<void> save(JournalEntry entry) async {
    await _box.put(entry.id, entry);
  }

  static List<JournalEntry> getAll() {
    return _box.values.toList();
  }

  static JournalEntry? getById(String id) => _box.get(id);

  static Future<void> update(JournalEntry entry) async {
    await _box.put(entry.id, entry);
    await SyncService.updateJournalEntry(entry);
  }

  static Future<void> delete(String id) async {
    await _box.delete(id);
    await SyncService.deleteJournalEntry(id);
  }

  static ValueListenable<Box<JournalEntry>> listenable() => _box.listenable();

  static Future<void> clearAll() async {
    await _box.clear();
  }
}
