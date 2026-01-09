import 'package:hive/hive.dart';

part 'mood.g.dart';

@HiveType(typeId: 3)
class Mood extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final int moodLevel;

  @HiveField(2)
  final DateTime createdAt;

  Mood({
    required this.date,
    required this.moodLevel,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get emoji {
    switch (moodLevel) {
      case 1:
        return '😢';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  int get color {
    switch (moodLevel) {
      case 1:
        return 0xFFE53E3E;
      case 2:
        return 0xFFF59E0B;
      case 3:
        return 0xFFEAB308;
      case 4:
        return 0xFF84CC16;
      case 5:
        return 0xFF14B8A6;
      default:
        return 0xFF84CC16;
    }
  }

  bool get isToday {
    final now = DateTime.now();
    final localDate = date.toLocal();
    return localDate.year == now.year && localDate.month == now.month && localDate.day == now.day;
  }

  @override
  String toString() => 'Mood(date: $date, level: $moodLevel)';
}
