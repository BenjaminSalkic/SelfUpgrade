import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/journal_service.dart';
import '../services/mood_service.dart';
import '../services/sync_service.dart';
import '../models/journal_entry.dart';
import '../models/goal.dart';
import '../models/mood.dart';
import '../widgets/responsive_container.dart';
import 'journal_entry_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const ProgressContent(),
    );
  }
}

class ProgressContent extends StatefulWidget {
  const ProgressContent({super.key});

  @override
  State<ProgressContent> createState() => _ProgressContentState();
}

class _ProgressContentState extends State<ProgressContent> {
  static const int heatmapDays = 60;
  String? _selectedGoalId;
  int _moodCalendarYear = DateTime.now().year;
  int? _highlightedMood;

  @override
  void initState() {
    super.initState();
    _loadSelectedGoal();
    _migrateAndResyncMoods();
  }

  Future<void> _migrateAndResyncMoods() async {
    final prefs = await SharedPreferences.getInstance();
    final hasMigrated = prefs.getBool('mood_timezone_fix_v2') ?? false;
    if (!hasMigrated) {
      await prefs.setBool('mood_timezone_fix_v2', true);
    }
  }

  Future<void> _loadSelectedGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final goalId = prefs.getString('selected_goal_id');
    if (goalId != null && mounted) {
      setState(() {
        _selectedGoalId = goalId;
      });
    }
  }

  Future<void> _saveSelectedGoal(String? goalId) async {
    final prefs = await SharedPreferences.getInstance();
    if (goalId != null) {
      await prefs.setString('selected_goal_id', goalId);
    } else {
      await prefs.remove('selected_goal_id');
    }
  }

  JournalEntry? _entryForDate(List<JournalEntry> entries, DateTime d) {
    final key = DateTime(d.year, d.month, d.day);
    for (var e in entries) {
      final eDate = DateTime(e.date.year, e.date.month, e.date.day);
      if (eDate == key) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      maxWidth: 1000,
      applyPadding: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 32),
        child: ValueListenableBuilder(
        valueListenable: JournalService.listenable(),
        builder: (context, box, _) {
          final entries = box.values.toList().cast<JournalEntry>();

          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          final startOfWeek = todayDate.subtract(Duration(days: todayDate.weekday - 1));
          int daysWithEntry = 0;
          final List<bool> weekPresence = List.generate(7, (i) {
            final d = startOfWeek.add(Duration(days: i));
            final exists = entries.any((e) => DateTime(e.date.year, e.date.month, e.date.day) == d);
            if (exists) daysWithEntry++;
            return exists;
          });

          final List<DateTime> heatDates = List.generate(heatmapDays, (i) => todayDate.subtract(Duration(days: heatmapDays - 1 - i)));

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Goal', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                _GoalTracker(
                  entries: entries,
                  selectedGoalId: _selectedGoalId,
                  onSelect: (id) {
                    setState(() => _selectedGoalId = id);
                    _saveSelectedGoal(id);
                  },
                ),

                const SizedBox(height: 12),

                Builder(builder: (ctx) {
                  final goals = Hive.box<Goal>('goals').values.toList().cast<Goal>();
                  final perfectDays = _computePerfectDays(entries, goals);
                  final avgPercent = _computeAverageCompletionPercent(entries, goals);
                  return Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0E10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4EF4C0).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Perfect Days', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 8),
                                Text(
                                  '${perfectDays}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0E10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4EF4C0).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Avg. per Day', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 8),
                                Text(
                                  '${avgPercent.toStringAsFixed(0)}%',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 24),

                Text('Activity', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                _MonthHeatmap(
                  entries: entries,
                  onDayTap: (date) {
                    final e = _entryForDate(entries, date);
                    if (e != null) Navigator.push(context, MaterialPageRoute(builder: (_) => JournalEntryScreen(entryId: e.id)));
                  },
                ),

                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mood', style: Theme.of(context).textTheme.headlineSmall),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Color(0xFFF3F3F3)),
                          onPressed: () => setState(() => _moodCalendarYear--),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF2A2D35)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _moodCalendarYear.toString(),
                            style: const TextStyle(
                              color: Color(0xFFF3F3F3),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Color(0xFFF3F3F3)),
                          onPressed: () {
                            if (_moodCalendarYear < DateTime.now().year) {
                              setState(() => _moodCalendarYear++);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildMoodCalendar(),
                const SizedBox(height: 16),
                _buildMoodSummary(),
              ],
            ),
          );
        },        ),      ),
    );
  }

  Widget _buildMoodCalendar() {
    try {
      final moods = MoodService.getMoodsForYear(_moodCalendarYear);

      final moodMap = <String, Mood>{};
      for (final mood in moods) {
        final localDate = mood.date.toLocal();
        final key = '${localDate.month}-${localDate.day}';
        moodMap[key] = mood;
      }

      final monthNames = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4EF4C0).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 20),
              ...monthNames.map((month) => SizedBox(
                    width: 20,
                    child: Text(
                      month,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 4),

          ...List.generate(31, (dayIndex) {
            final day = dayIndex + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      day.toString(),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  ...List.generate(12, (monthIndex) {
                    final month = monthIndex + 1;
                    final key = '$month-$day';
                    final mood = moodMap[key];

                    final daysInMonth = DateTime(_moodCalendarYear, month + 1, 0).day;
                    if (day > daysInMonth) {
                      return const SizedBox(width: 20);
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
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D23),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No mood data available',
            style: TextStyle(color: Color(0xFF888888)),
          ),
        ),
      );
    }
  }

  Widget _buildMoodDot(Mood? mood) {
    if (mood == null) {
      return Container(
        width: 20,
        height: 16,
        alignment: Alignment.center,
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Color(0xFF414141),
            shape: BoxShape.circle,
          ),
        ),
      );
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
        width: 20,
        height: 14,
        alignment: Alignment.center,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Color(mood.color).withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSummary() {
    try {
      final counts = MoodService.getMoodCountsForYear(_moodCalendarYear);
      
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMoodCount(1, const Color(0xFFE53E3E), (counts[1] ?? 0) as int),
          _buildMoodCount(2, const Color(0xFFF59E0B), (counts[2] ?? 0) as int),
          _buildMoodCount(3, const Color(0xFFEAB308), (counts[3] ?? 0) as int),
          _buildMoodCount(4, const Color(0xFF84CC16), (counts[4] ?? 0) as int),
          _buildMoodCount(5, const Color(0xFF14B8A6), (counts[5] ?? 0) as int),
        ],
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildMoodCount(int level, Color color, int count) {
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
              (count).toString(),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: CustomPaint(
                painter: _MoodFacePainter(level, color: const Color(0xFF2A2D35)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _computeLongestStreak(List<JournalEntry> entries, {int daysBack = 30}) {
    if (entries.isEmpty) return 0;
    final today = DateTime.now();
    final start = today.subtract(Duration(days: daysBack));
    final uniqueDates = <String>{};
    for (var e in entries) {
      if (e.date.isAfter(start)) {
        final dateKey = '${e.date.year}-${e.date.month}-${e.date.day}';
        uniqueDates.add(dateKey);
      }
    }
    
    final dates = uniqueDates
        .map((key) {
          final parts = key.split('-');
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        })
        .toList()
      ..sort();

    int best = 0;
    int cur = 0;
    DateTime? prev;
    for (var d in dates) {
      if (prev == null || d.difference(prev).inDays == 1) {
        cur += 1;
      } else {
        cur = 1;
      }
      prev = d;
      if (cur > best) best = cur;
    }
    return best;
  }

  bool _isDoneResponse(String? resp) {
    if (resp == null) return false;
    final v = resp.toLowerCase().trim();
    return v == 'done' || v == 'yes' || v == 'true' || v == '1' || v == 'y';
  }

  int _computePerfectDays(List<JournalEntry> entries, List<Goal> goals) {
    final activeGoals = goals.where((g) => g.isActive).toList();
    if (activeGoals.isEmpty) return 0;
    
    final dayGoals = <String, Set<String>>{};
    for (var e in entries) {
      final dateKey = '${e.createdAt.year}-${e.createdAt.month}-${e.createdAt.day}';
      dayGoals.putIfAbsent(dateKey, () => <String>{});
      dayGoals[dateKey]!.addAll(e.goalTags);
    }
    
    int perfect = 0;
    for (var goalTags in dayGoals.values) {
      bool allDone = true;
      for (var g in activeGoals) {
        if (!goalTags.contains(g.id)) {
          allDone = false;
          break;
        }
      }
      if (allDone) perfect++;
    }
    return perfect;
  }

  double _computeAverageCompletionPercent(List<JournalEntry> entries, List<Goal> goals) {
    final activeGoals = goals.where((g) => g.isActive).toList();
    if (activeGoals.isEmpty) return 0.0;
    
    final dayGoals = <String, Set<String>>{};
    for (var e in entries) {
      final dateKey = '${e.createdAt.year}-${e.createdAt.month}-${e.createdAt.day}';
      dayGoals.putIfAbsent(dateKey, () => <String>{});
      dayGoals[dateKey]!.addAll(e.goalTags);
    }
    
    if (dayGoals.isEmpty) return 0.0;
    
    double sumPercent = 0.0;
    for (var goalTags in dayGoals.values) {
      int done = 0;
      for (var g in activeGoals) {
        if (goalTags.contains(g.id)) done++;
      }
      sumPercent += (done / activeGoals.length) * 100.0;
    }
    return sumPercent / dayGoals.length;
  }
}

class _WeekBar extends StatelessWidget {
  final List<bool> presence;
  const _WeekBar({required this.presence});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: presence
          .map((p) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 26,
                  height: 6,
                  decoration: BoxDecoration(
                    color: p ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _MonthHeatmap extends StatelessWidget {
  final List<JournalEntry> entries;
  final void Function(DateTime) onDayTap;

  const _MonthHeatmap({required this.entries, required this.onDayTap});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month, 1);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final startWeekday = firstDay.weekday;

    return LayoutBuilder(builder: (context, constraints) {
      final cellWidth = (constraints.maxWidth - 8) / 7;
      List<Widget> rows = [];

      rows.add(Row(
        children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        .map((d) => Expanded(child: SizedBox(height: 20, child: Center(child: Text(d, style: TextStyle(color: Colors.grey.shade400))))))
        .toList(),
      ));

      int day = 1;
      for (int week = 0; week < 6; week++) {
        List<Widget> cols = [];
        for (int wd = 1; wd <= 7; wd++) {
          final shouldShow = (week == 0 && wd >= startWeekday) || (week > 0 && day <= daysInMonth);
            if (shouldShow) {
            final current = DateTime(today.year, today.month, day);
            final currentDateKey = '${current.year}-${current.month}-${current.day}';
            final has = entries.any((e) {
              final entryDateKey = '${e.createdAt.year}-${e.createdAt.month}-${e.createdAt.day}';
              return entryDateKey == currentDateKey;
            });
            
            final isToday = DateTime.now().year == current.year && DateTime.now().month == current.month && DateTime.now().day == current.day;
            final bgColor = has ? Theme.of(context).colorScheme.primary : Colors.grey.shade800;

            cols.add(Expanded(
              child: SizedBox(
                height: 48,
                child: GestureDetector(
                  onTap: () => onDayTap(current),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                      child: Center(
                        child: Text(
                          day.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ));
            day++;
          } else {
            cols.add(Expanded(child: SizedBox(height: 48)));
          }
        }
        rows.add(Row(children: cols));
        if (day > daysInMonth) break;
      }

      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF4EF4C0).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: rows),
        ),
      );
    });
  }
}

class _ProgressSignals extends StatelessWidget {
  final int longestStreak;
  const _ProgressSignals({required this.longestStreak});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF4EF4C0).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Momentum', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('Your longest writing streak this month: $longestStreak ${longestStreak == 1 ? 'day' : 'days'}'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalTracker extends StatefulWidget {
  final List<JournalEntry> entries;
  final String? selectedGoalId;
  final void Function(String?) onSelect;

  const _GoalTracker({required this.entries, required this.selectedGoalId, required this.onSelect});

  @override
  State<_GoalTracker> createState() => _GoalTrackerState();
}

class _GoalTrackerState extends State<_GoalTracker> {
  Box<Goal> get _goalsBox => Hive.box<Goal>('goals');

  int _countMentions(String goalId, List<JournalEntry> entries) {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    
    final daysWithGoal = <String>{};
    for (var e in entries) {
      final ed = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      if (ed.isBefore(weekStart)) continue;
      if (e.goalTags.contains(goalId)) {
        final dateKey = '${ed.year}-${ed.month}-${ed.day}';
        daysWithGoal.add(dateKey);
      }
    }
    
    return daysWithGoal.length;
  }

  @override
  Widget build(BuildContext context) {
    final goals = _goalsBox.values.toList().cast<Goal>();
    Goal? selected;
    if (widget.selectedGoalId != null) {
      try {
        selected = goals.firstWhere((g) => g.id == widget.selectedGoalId);
      } catch (_) {
        selected = null;
      }
    }

    const tileSize = 160.0;
    return SizedBox(
      width: tileSize,
      height: tileSize,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF4EF4C0).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: Builder(builder: (context) {
                  const int target = 7;
                  final int mentions = selected == null ? 0 : _countMentions(selected.id, widget.entries);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: selected == null ? 0 : (mentions / target).clamp(0.0, 1.0),
                          strokeWidth: 6,
                          backgroundColor: Colors.grey.shade800,
                          color: const Color(0xFF4EF4C0),
                        ),
                      ),
                      if (selected != null)
                        Text(
                          '$mentions/$target',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        )
                      else
                        const Icon(Icons.flag, size: 24),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showModalBottomSheet<String?>(
                      context: context,
                      backgroundColor: const Color(0xFF0A0E12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                      builder: (ctx) {
                        final list = _goalsBox.values.toList().cast<Goal>();
                        return Container(
                          color: const Color(0xFF0A0E12),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: list.length + 1,
                            separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                            itemBuilder: (c, i) {
                              if (i == 0) {
                                return ListTile(
                                  title: const Text('None', style: TextStyle(color: Colors.white)),
                                  onTap: () => Navigator.of(ctx).pop(null),
                                  tileColor: Colors.transparent,
                                );
                              }
                              final g = list[i - 1] as Goal;
                              final gid = g.id;
                              final title = g.title;
                              return ListTile(
                                title: Text(title, style: const TextStyle(color: Colors.white)),
                                subtitle: Text(g.category ?? '', style: TextStyle(color: Colors.white70)),
                                onTap: () => Navigator.of(ctx).pop(gid),
                                tileColor: Colors.transparent,
                              );
                            },
                          ),
                        );
                      },
                    );
                    widget.onSelect(picked);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        selected != null ? selected.title : 'Choose a goal',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodFacePainter extends CustomPainter {
  final int level;
  final Color color;

  _MoodFacePainter(this.level, {this.color = const Color(0xFF2A2D35)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final eyeY = center.dy - 6;
    final eyeRadius = 2.5;

    if (level == 1) {
      final leftEyeCenter = Offset(center.dx - 10, eyeY);
      final rightEyeCenter = Offset(center.dx + 10, eyeY);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      
      canvas.drawLine(
        Offset(leftEyeCenter.dx - 3, leftEyeCenter.dy - 3),
        Offset(leftEyeCenter.dx + 3, leftEyeCenter.dy + 3),
        paint,
      );
      canvas.drawLine(
        Offset(leftEyeCenter.dx + 3, leftEyeCenter.dy - 3),
        Offset(leftEyeCenter.dx - 3, leftEyeCenter.dy + 3),
        paint,
      );
      
      canvas.drawLine(
        Offset(rightEyeCenter.dx - 3, rightEyeCenter.dy - 3),
        Offset(rightEyeCenter.dx + 3, rightEyeCenter.dy + 3),
        paint,
      );
      canvas.drawLine(
        Offset(rightEyeCenter.dx + 3, rightEyeCenter.dy - 3),
        Offset(rightEyeCenter.dx - 3, rightEyeCenter.dy + 3),
        paint,
      );
      paint.style = PaintingStyle.fill;
    } else {
      canvas.drawCircle(Offset(center.dx - 10, eyeY), eyeRadius, paint);
      canvas.drawCircle(Offset(center.dx + 10, eyeY), eyeRadius, paint);
    }

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.5;
    paint.strokeCap = StrokeCap.round;

    final mouthY = center.dy + 8;
    
    switch (level) {
      case 1:
        final path = Path();
        path.moveTo(center.dx - 12, mouthY - 2);
        path.quadraticBezierTo(center.dx, mouthY - 8, center.dx + 12, mouthY - 2);
        canvas.drawPath(path, paint);
        break;
      case 2:
        final path = Path();
        path.moveTo(center.dx - 12, mouthY);
        path.quadraticBezierTo(center.dx, mouthY - 4, center.dx + 12, mouthY);
        canvas.drawPath(path, paint);
        break;
      case 3:
        canvas.drawLine(
          Offset(center.dx - 12, mouthY),
          Offset(center.dx + 12, mouthY),
          paint,
        );
        break;
      case 4:
        final path = Path();
        path.moveTo(center.dx - 12, mouthY);
        path.quadraticBezierTo(center.dx, mouthY + 4, center.dx + 12, mouthY);
        canvas.drawPath(path, paint);
        break;
      case 5:
        final path = Path();
        path.moveTo(center.dx - 12, mouthY - 2);
        path.quadraticBezierTo(center.dx, mouthY + 6, center.dx + 12, mouthY - 2);
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
