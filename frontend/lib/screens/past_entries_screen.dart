import 'package:flutter/material.dart';
import 'dart:math';
import '../services/journal_service.dart';
import '../models/journal_entry.dart';
import 'journal_entry_screen.dart';
import '../widgets/responsive_container.dart';

class PastEntriesScreen extends StatelessWidget {
  const PastEntriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveContainer(
        maxWidth: 1000,
        applyPadding: false,
      child: ValueListenableBuilder(
        valueListenable: JournalService.listenable(),
        builder: (context, box, _) {
          final entries = box.values.toList().reversed.toList().cast<JournalEntry>();
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No past entries',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your journal entries will appear here',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final JournalEntry entry = entries[index];
              final preview = entry.content.length > 80 ? '${entry.content.substring(0, 80)}…' : entry.content;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(Icons.star, color: Theme.of(context).colorScheme.primary, size: 20),
                  title: Text(entry.createdAt.toLocal().toString()),
                  subtitle: Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => JournalEntryScreen(entryId: entry.id)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }
}

class PastEntriesContent extends StatefulWidget {
  const PastEntriesContent({super.key});

  @override
  State<PastEntriesContent> createState() => _PastEntriesContentState();
}

class _PastEntriesContentState extends State<PastEntriesContent> {
  final Map<String, Offset> _positions = {};
  final Map<String, Size> _sizes = {};
  final _random = Random();
  Set<String> _dragging = <String>{};

  void _ensurePositions(List<JournalEntry> entries, Size area) {
    for (var e in entries) {
      if (!_positions.containsKey(e.id)) {
        final dx = _random.nextDouble() * (area.width - 60).clamp(50, area.width);
        final dy = _random.nextDouble() * (area.height - 60).clamp(50, area.height);
        _positions[e.id] = Offset(dx, dy);
      }
    }
    _positions.keys.toList().forEach((k) {
      if (!entries.any((e) => e.id == k)) _positions.remove(k);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final area = Size(constraints.maxWidth, constraints.maxHeight > 0 ? constraints.maxHeight : 600);
      return ValueListenableBuilder(
        valueListenable: JournalService.listenable(),
        builder: (context, box, _) {
          final entries = box.values.toList().reversed.toList().cast<JournalEntry>();
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No past entries',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your journal entries will appear here',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      for (var i = 0; i < 6; i++) {
                        final id = '${now.millisecondsSinceEpoch}-$i';
                        final entry = JournalEntry(
                          id: id,
                          date: now.subtract(Duration(days: i)),
                          content: 'Sample entry #${i + 1}\nNode style',
                          linkedEntryIds: const [],
                          goalResponses: const {},
                          createdAt: now.subtract(Duration(days: i)),
                          updatedAt: null,
                        );
                        await JournalService.add(entry);
                      }
                    },
                    child: const Text('Add sample entries'),
                  ),
                ],
              ),
            );
          }

          _ensurePositions(entries, area);

          return GestureDetector(
            onTap: () {},
            child: SizedBox(
              height: area.height,
              width: area.width,
              child: Stack(
                children: entries.map((entry) {
                  final pos = _positions[entry.id] ?? Offset(area.width / 2, area.height / 2);
                  final titleLine = entry.content.split('\n').first.trim();
                  final label = titleLine.isNotEmpty ? titleLine : '(No title)';
                  final isDragging = _dragging.contains(entry.id);

                  Widget item = GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: (_) {
                      setState(() => _dragging.add(entry.id));
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        final current = _positions[entry.id] ?? Offset(area.width / 2, area.height / 2);
                        final updated = current + details.delta;
                        _positions[entry.id] = Offset(
                          updated.dx.clamp(0.0, (area.width - 40).clamp(0.0, area.width)),
                          updated.dy.clamp(0.0, (area.height - 40).clamp(0.0, area.height)),
                        );
                      });
                    },
                    onPanEnd: (_) {
                      setState(() => _dragging.remove(entry.id));
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => JournalEntryScreen(entryId: entry.id)),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDot(context),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 120,
                          child: Text(
                            label,
                            style: const TextStyle(color: Color(0xFFF3F3F3), fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );

                  return isDragging
                      ? Positioned(
                          key: ValueKey('${entry.id}-pos'),
                          left: pos.dx,
                          top: pos.dy,
                          child: item,
                        )
                      : AnimatedPositioned(
                          key: ValueKey(entry.id),
                          left: pos.dx,
                          top: pos.dy,
                          duration: const Duration(milliseconds: 240),
                          child: item,
                        );
                }).toList(),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildDot(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 6, spreadRadius: 1),
        ],
      ),
    );
  }
}
