import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'api_service.dart';
import 'journal_service.dart';
import 'goal_service.dart';
import 'user_service.dart';
import 'auth_service.dart';
import 'mood_service.dart';
import '../models/journal_entry.dart';
import '../models/goal.dart';
import '../models/user.dart';
import '../models/mood.dart';

class SyncService {
  static ApiService? _apiService;
  static bool _isSyncing = false;

  static void initialize(ApiService apiService) {
    _apiService = apiService;
  }

  static Future<bool> syncJournalEntry(JournalEntry entry) async {
    if (_apiService == null) {
      return false;
    }
    if (_isSyncing) {
      return false;
    }

    try {
      final mood = await MoodService.getMood(entry.createdAt);
      final data = {
        'id': entry.id,
        'content': entry.content,
        'goal_tags': entry.goalTags,
        'mood': mood,
        'date': entry.date.toIso8601String(),
      };

      final result = await _apiService!.post('/api/journal-entries', data);
      if (result != null) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Sync journal entry failed: $e');
      return false;
    }
  }

  static Future<bool> updateJournalEntry(JournalEntry entry) async {
    if (_apiService == null) return false;
    if (_isSyncing) return false;

    try {
      final mood = await MoodService.getMood(entry.createdAt);
      final data = {
        'content': entry.content,
        'goal_tags': entry.goalTags,
        'mood': mood,
        'date': entry.date.toIso8601String(),
      };

      await _apiService!.put('/api/journal-entries/${entry.id}', data);
      return true;
    } catch (e) {
      print('Update journal entry failed: $e');
      return false;
    }
  }

  static Future<bool> deleteJournalEntry(String id) async {
    if (_apiService == null) return false;
    if (_isSyncing) return false;

    try {
      await _apiService!.delete('/api/journal-entries/$id');
      return true;
    } catch (e) {
      print('Delete journal entry failed: $e');
      return false;
    }
  }

  static Future<bool> syncGoal(Goal goal, {bool isNew = false}) async {
    if (_apiService == null) return false;
    if (_isSyncing) return false;

    try {
      if (isNew) {
        final data = {
          'id': goal.id,
          'title': goal.title,
          'description': goal.description,
          'category': goal.category,
          'is_active': goal.isActive,
        };
        await _apiService!.post('/api/goals', data);
      } else {
        final data = {
          'title': goal.title,
          'description': goal.description,
          'category': goal.category,
          'is_active': goal.isActive,
        };
        await _apiService!.put('/api/goals/${goal.id}', data);
      }
      return true;
    } catch (e) {
      print('Sync goal failed: $e');
      return false;
    }
  }

  static Future<bool> updateGoal(Goal goal) async {
    if (_apiService == null) return false;
    if (_isSyncing) return false;

    try {
      final data = {
        'title': goal.title,
        'description': goal.description,
        'category': goal.category,
        'is_active': goal.isActive,
      };

      await _apiService!.put('/api/goals/${goal.id}', data);
      return true;
    } catch (e) {
      print('Update goal failed: $e');
      return false;
    }
  }

  static Future<bool> deleteGoal(String id) async {
    if (_apiService == null) return false;
    if (_isSyncing) return false;

    try {
      await _apiService!.delete('/api/goals/$id');
      return true;
    } catch (e) {
      print('Delete goal failed: $e');
      return false;
    }
  }

  static Future<bool> syncUser(User user) async {
    if (_apiService == null) return false;
    if (_isSyncing) return false;

    try {
      final data = {
        'name': user.name,
        'email': user.email,
        'age': null,
        'has_completed_onboarding': user.hasCompletedOnboarding,
      };

      await _apiService!.put('/api/users/me', data);
      return true;
    } catch (e) {
      print('Sync user failed: $e');
      return false;
    }
  }

  static Future<bool> syncAll() async {
    if (_apiService == null) return false;
    if (_isSyncing) return false;

    _isSyncing = true;
    try {
      final entries = JournalService.getAll();
      final goals = GoalService.getAll();
      final user = UserService.getCurrent();

      final journalData = entries.map((e) => {
        'id': e.id,
        'content': e.content,
        'goal_tags': e.goalTags,
        'mood': null,
        'date': e.date.toIso8601String(),
        'created_at': e.createdAt.toIso8601String(),
        'updated_at': e.createdAt.toIso8601String(),
      }).toList();

      final goalsData = goals.map((g) => {
        'id': g.id,
        'title': g.title,
        'description': g.description,
        'category': g.category,
        'is_active': g.isActive,
        'created_at': g.createdAt.toIso8601String(),
        'updated_at': g.createdAt.toIso8601String(),
      }).toList();

      final userData = user != null ? {
        'name': user.name,
        'email': user.email,
        'age': null,
        'has_completed_onboarding': user.hasCompletedOnboarding,
      } : null;

      final syncData = {
        'journal_entries': journalData,
        'goals': goalsData,
        if (userData != null) 'user': userData,
      };

      await _apiService!.post('/api/sync', syncData);
      _isSyncing = false;
      return true;
    } catch (e) {
      print('Full sync failed: $e');
      _isSyncing = false;
      return false;
    }
  }

  static Future<void> pullFromServer() async {
    if (_apiService == null) {
      return;
    }
    if (_isSyncing) {
      return;
    }

    _isSyncing = true;
    try {
      final entriesResponse = await _apiService!.get('/api/journal-entries');
      final goalsResponse = await _apiService!.get('/api/goals');
      final userResponse = await _apiService!.get('/api/users/me');

      if (entriesResponse != null && entriesResponse['data'] != null) {
        for (var entryData in entriesResponse['data']) {
          final entry = JournalEntry(
            id: entryData['id'],
            content: entryData['content'] ?? '',
            goalTags: List<String>.from(entryData['goal_tags'] ?? []),
            date: DateTime.parse(entryData['date']),
            createdAt: DateTime.parse(entryData['created_at']),
          );
          await JournalService.save(entry);
        }
      }

      if (goalsResponse != null && goalsResponse['data'] != null) {
        for (var goalData in goalsResponse['data']) {
          final goal = Goal(
            id: goalData['id'],
            title: goalData['title'],
            description: goalData['description'] ?? '',
            category: goalData['category'] ?? '',
            createdAt: DateTime.parse(goalData['created_at']),
            isActive: goalData['is_active'] ?? true,
          );
          await GoalService.save(goal);
        }
      }

      if (userResponse != null && userResponse['data'] != null) {
        final userData = userResponse['data'];
        final user = User(
          id: userData['id'],
          name: userData['name'],
          email: userData['email'],
          createdAt: DateTime.parse(userData['created_at']),
          hasCompletedOnboarding: userData['has_completed_onboarding'] ?? false,
          auth0Id: userData['auth0_id'],
        );
        await UserService.saveCurrent(user);
      }

      final moodsResponse = await _apiService!.get('/api/moods');
      if (moodsResponse != null && moodsResponse['data'] != null) {
        final moodsList = moodsResponse['data'] as List;

        if (moodsList.isNotEmpty) {
          await MoodService.clearAll();

          for (var moodData in moodsList) {
            try {
              final dateString = moodData['date'] as String;

              DateTime localDate;
              if (dateString.contains('T')) {
                final utcDate = DateTime.parse(dateString);
                localDate = DateTime(utcDate.toLocal().year, utcDate.toLocal().month, utcDate.toLocal().day);
              } else {
                final parts = dateString.split('-');
                localDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
              }

              await MoodService.saveMood(localDate, moodData['mood_level']);
            } catch (e) {
              print('Error parsing mood: $e, data: $moodData');
            }
          }
        }
      }

      _isSyncing = false;
    } catch (e) {
      print('Pull from server failed: $e');
      _isSyncing = false;
    }
  }

  static Future<bool> syncMood(DateTime date, int moodLevel) async {
    if (_apiService == null) return false;
    if (_isSyncing) return false;

    try {
      final dateOnly = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final data = {
        'date': dateOnly,
        'mood_level': moodLevel,
      };

      await _apiService!.post('/api/moods', data);
      return true;
    } catch (e) {
      print('Sync mood failed: $e');
      return false;
    }
  }
}
