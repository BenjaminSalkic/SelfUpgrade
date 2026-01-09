import 'package:flutter/material.dart';
import '../services/mood_service.dart';
import '../models/mood.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedYear = DateTime.now().year;
  int? _highlightedMood;
  static const bgColor = Color(0xFF0A0E12);

  List<String> get _monthNames => ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

  @override
  Widget build(BuildContext context) {
    final moods = MoodService.getMoodsForYear(_selectedYear);
    final moodCounts = MoodService.getMoodCountsForYear(_selectedYear);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFFF3F3F3)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Stats',
          style: TextStyle(color: Color(0xFFF3F3F3), fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Color(0xFFF3F3F3)),
                  onPressed: () => setState(() => _selectedYear--),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF2A2D35)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _selectedYear.toString(),
                    style: const TextStyle(
                      color: Color(0xFFF3F3F3),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xFFF3F3F3)),
                  onPressed: () {
                    if (_selectedYear < DateTime.now().year) {
                      setState(() => _selectedYear++);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D23),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.tag_faces, color: Color(0xFF4EF4C0), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'average mood ',
                    style: TextStyle(color: Color(0xFFF3F3F3), fontSize: 16),
                  ),
                  Text(
                    '(${moods.length}×)',
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: Color(0xFF888888)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildCalendarGrid(moods),
            const SizedBox(height: 32),

            _buildMoodSummary(moodCounts),
            const SizedBox(height: 16),

            const Text(
              'Tap mood to highlight it on the chart',
              style: TextStyle(color: Color(0xFF888888), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(List<Mood> moods) {
    final moodMap = <String, Mood>{};
    for (final mood in moods) {
      final key = '${mood.date.month}-${mood.date.day}';
      moodMap[key] = mood;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D23),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24),
              ..._monthNames.map((month) => SizedBox(
                    width: 24,
                    child: Text(
                      month,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 8),

          ...List.generate(31, (dayIndex) {
            final day = dayIndex + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      day.toString(),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  ...List.generate(12, (monthIndex) {
                    final month = monthIndex + 1;
                    final key = '$month-$day';
                    final mood = moodMap[key];

                    final daysInMonth = DateTime(_selectedYear, month + 1, 0).day;
                    if (day > daysInMonth) {
                      return const SizedBox(width: 24);
                    }

                    return _buildMoodDot(mood);
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMoodDot(Mood? mood) {
    if (mood == null) {
      return const SizedBox(width: 24);
    }

    final isHighlighted = _highlightedMood == null || _highlightedMood == mood.moodLevel;
    final opacity = isHighlighted ? 1.0 : 0.2;

    return GestureDetector(
      onTap: () {
        setState(() {
          _highlightedMood = _highlightedMood == mood.moodLevel ? null : mood.moodLevel;
        });
      },
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Color(mood.color).withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSummary(Map<int, int> counts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMoodCount(5, '😄', counts[5] ?? 0, const Color(0xFF14B8A6)),
        _buildMoodCount(4, '🙂', counts[4] ?? 0, const Color(0xFF84CC16)),
        _buildMoodCount(3, '😐', counts[3] ?? 0, const Color(0xFFEAB308)),
        _buildMoodCount(2, '😕', counts[2] ?? 0, const Color(0xFFF59E0B)),
        _buildMoodCount(1, '😢', counts[1] ?? 0, const Color(0xFFE53E3E)),
      ],
    );
  }

  Widget _buildMoodCount(int level, String emoji, int count, Color color) {
    final isHighlighted = _highlightedMood == null || _highlightedMood == level;

    return GestureDetector(
      onTap: () {
        setState(() {
          _highlightedMood = _highlightedMood == level ? null : level;
        });
      },
      child: Opacity(
        opacity: isHighlighted ? 1.0 : 0.3,
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
