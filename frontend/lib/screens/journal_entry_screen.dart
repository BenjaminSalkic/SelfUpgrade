import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../services/mood_service.dart';
import '../services/goal_service.dart';
import '../services/sync_service.dart';
import '../models/mood.dart';
import '../models/goal.dart';
import '../widgets/responsive_container.dart';

class JournalEntryScreen extends StatefulWidget {
  final String? entryId;
  const JournalEntryScreen({super.key, this.entryId});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<JournalEntry> _pastEntries = [];
  final List<String> _linkedEntryIds = [];
  final List<String> _selectedGoalTags = [];
  static const bgColor = Color(0xFF0A0E12);
  bool _showFormatted = false;
  
  Timer? _inactivityTimer;
  String _currentPrompt = '';
  int _promptIndex = 0;
  bool _showPrompt = false;
  static const Duration _inactivityDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _loadPastEntries();
    if (widget.entryId != null) {
      _loadEntry(widget.entryId!);
    } else {
      final now = DateTime.now();
      final defaultTitle = 'Jurnal ${now.day}-${now.month}-${now.year}';
      if (_controller.text.trim().isEmpty) {
        _controller.text = '$defaultTitle\n\n';
        _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      }
    }
    
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    
    if (widget.entryId == null) {
      _startInactivityTimer();
    }
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  void _onTextChanged() {
    if (_showPrompt) {
      setState(() {
        _showPrompt = false;
      });
    }
    
    _resetInactivityTimer();
  }
  
  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _startInactivityTimer();
    } else {
      _inactivityTimer?.cancel();
      setState(() {
        _showPrompt = false;
      });
    }
  }
  
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, _showWritingPrompt);
  }
  
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (_focusNode.hasFocus) {
      _inactivityTimer = Timer(_inactivityDuration, _showWritingPrompt);
    }
  }
  
  void _showWritingPrompt() {
    if (!mounted || !_focusNode.hasFocus) return;
    
    final prompts = _generatePrompts();
    if (prompts.isEmpty) return;
    
    setState(() {
      _currentPrompt = prompts[_promptIndex % prompts.length];
      _promptIndex++;
      _showPrompt = true;
    });
    
  }
  
  List<String> _generatePrompts() {
    final goals = GoalService.getActive();
    final prompts = <String>[];
    final now = DateTime.now();
    final isSunday = now.weekday == DateTime.sunday;
    final hour = now.hour;
    
    if (isSunday && hour >= 17) {
      prompts.addAll([
        '🌟 Weekly Review: What were your biggest wins this week?',
        '📊 Weekly Review: What lessons did you learn this week?',
        '🎯 Weekly Review: How did you progress on your goals?',
        '💭 Weekly Review: What do you want to improve next week?',
        '⭐ Weekly Review: Rate your week out of 10 and explain why',
        '🔄 Weekly Review: What patterns did you notice this week?',
        '💪 Weekly Review: What are you most proud of this week?',
        '🚀 Weekly Review: What\'s your main focus for next week?',
      ]);
    }
    
    if (goals.isNotEmpty) {
      for (final goal in goals) {
        prompts.addAll([
          'What progress have you made on "${goal.title}"?',
          'Any updates about ${goal.title}?',
          'What did you accomplish today toward "${goal.title}"?',
          'How much closer are you to "${goal.title}" than yesterday?',
          'What\'s the latest with ${goal.title}?',
          
          'How do you feel about your progress on "${goal.title}"?',
          'Are you excited about "${goal.title}" right now?',
          'What\'s your energy level for ${goal.title} today?',
          'How confident do you feel about achieving "${goal.title}"?',
          
          'What challenges are you facing with "${goal.title}"?',
          'What\'s blocking your progress on ${goal.title}?',
          'What obstacles did you overcome for "${goal.title}"?',
          'What\'s been harder than expected with ${goal.title}?',
          'What support do you need for "${goal.title}"?',
          
          'What\'s your next step for "${goal.title}"?',
          'What\'s one small action you can take on ${goal.title} today?',
          'What will you do tomorrow to advance "${goal.title}"?',
          'What\'s the most important thing to focus on for ${goal.title}?',
          'When will you work on "${goal.title}" next?',
          
          'What win can you celebrate for "${goal.title}"?',
          'What went well with ${goal.title} today?',
          'What are you proud of regarding "${goal.title}"?',
          'What breakthrough did you have with ${goal.title}?',
          
          'What did you learn while working on "${goal.title}"?',
          'How has "${goal.title}" changed you?',
          'What surprised you about ${goal.title}?',
          'What would you do differently with "${goal.title}"?',
          
          'Why is "${goal.title}" important to you?',
          'What motivates you to keep working on ${goal.title}?',
          'How will achieving "${goal.title}" change your life?',
          'What inspired you to start ${goal.title}?',
          
          'How much time did you spend on "${goal.title}" today?',
          'How consistent have you been with ${goal.title}?',
          'What\'s your streak for "${goal.title}"?',
          'When was the last time you worked on ${goal.title}?',
          
          'What strategy is working for "${goal.title}"?',
          'How could you approach ${goal.title} differently?',
          'What resources do you need for "${goal.title}"?',
          'Who could help you with ${goal.title}?',
        ]);
      }
    }
    
    prompts.addAll([
      'What made today meaningful?',
      'What did you learn today?',
      'What are you grateful for today?',
      'What challenged you today?',
      'How are you feeling right now?',
      'What went well today?',
      'What could have gone better?',
      'Who did you connect with today?',
      'What surprised you today?',
      'What are you looking forward to?',
      'What\'s on your mind?',
      'How did you take care of yourself today?',
      'What made you smile today?',
      'What are you proud of today?',
      'What would you like to remember about today?',
    ]);
    
    if (hour >= 5 && hour < 12) {
      prompts.addAll([
        'How are you starting your day?',
        'What are your intentions for today?',
        'What energy are you bringing to today?',
      ]);
    } else if (hour >= 12 && hour < 17) {
      prompts.addAll([
        'How is your day unfolding?',
        'What\'s been the highlight so far?',
        'How are you managing your energy?',
      ]);
    } else if (hour >= 17 && hour < 22) {
      prompts.addAll([
        'What stood out about today?',
        'How do you feel about how today went?',
        'What moments from today do you want to remember?',
      ]);
    } else {
      prompts.addAll([
        'What\'s keeping you up right now?',
        'How are you winding down?',
        'What do you need to let go of before sleep?',
      ]);
    }
    
    return prompts;
  }
  
  double _getPromptPosition() {
    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;
    
    if (cursorPos < 0 || text.isEmpty) return 0;
    
    final textBeforeCursor = text.substring(0, cursorPos.clamp(0, text.length));
    final lineNumber = '\n'.allMatches(textBeforeCursor).length;
    
    return lineNumber * 27.2;
  }

  void _loadEntry(String id) {
    final e = JournalService.getById(id);
    if (e != null) {
      _controller.text = e.content;
      _linkedEntryIds
        ..clear()
        ..addAll(e.linkedEntryIds);
      _selectedGoalTags
        ..clear()
        ..addAll(e.goalTags);
    }
  }

  Future<void> _loadPastEntries() async {
    final entries = JournalService.getAll();
    setState(() {
      _pastEntries
        ..clear()
        ..addAll(entries.reversed);
    });
  }

  void _insertTextAtSelection(String insertText) {
    final text = _controller.text;
    final sel = _controller.selection;
    final start = sel.start < 0 ? text.length : sel.start;
    final end = sel.end < 0 ? text.length : sel.end;
    final newText = text.replaceRange(start, end, insertText);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + insertText.length),
    );
  }

  void _insertBulletPoint() => _insertTextAtSelection('• ');


  void _saveEntry() async {
    final contentTrimmed = _controller.text.trim();
    if (contentTrimmed.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final id = widget.entryId ?? Uuid().v4();
    final existing = widget.entryId != null ? JournalService.getById(id) : null;
    final entry = JournalEntry(
      id: id,
      date: existing?.date ?? DateTime.now(),
      content: _controller.text,
      linkedEntryIds: List.from(_linkedEntryIds),
      goalResponses: existing?.goalResponses ?? {},
      goalTags: List.from(_selectedGoalTags),
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    if (widget.entryId != null) {
      await JournalService.update(entry);
    } else {
      await JournalService.add(entry);
    }

    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!MoodService.hasLoggedToday()) {
      if (mounted) {
        await _showMoodPicker();
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _showMoodPicker() async {
    final selectedMood = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A0E11),
          title: const Text(
            'How are you feeling today?',
            style: TextStyle(color: Color(0xFFF3F3F3)),
            textAlign: TextAlign.center,
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMoodButton(1, const Color(0xFFE53E3E)),
              const SizedBox(width: 12),
              _buildMoodButton(2, const Color(0xFFF59E0B)),
              const SizedBox(width: 12),
              _buildMoodButton(3, const Color(0xFFEAB308)),
              const SizedBox(width: 12),
              _buildMoodButton(4, const Color(0xFF84CC16)),
              const SizedBox(width: 12),
              _buildMoodButton(5, const Color(0xFF14B8A6)),
            ],
          ),
        );
      },
    );

    if (selectedMood != null) {
      await MoodService.saveMood(DateTime.now(), selectedMood);
      await SyncService.syncMood(DateTime.now(), selectedMood);
    }
  }

  Future<void> _showGoalTagsPicker() async {
    final goals = GoalService.getActive();
    
    if (goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active goals. Create goals in Settings first.'),
          backgroundColor: Color(0xFF1A1D23),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF0A0E11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tag Goals',
                      style: TextStyle(
                        color: Color(0xFFF3F3F3),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: goals.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final goal = goals[index];
                          final isSelected = _selectedGoalTags.contains(goal.id);
                          
                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                setState(() {
                                  if (isSelected) {
                                    _selectedGoalTags.remove(goal.id);
                                  } else {
                                    _selectedGoalTags.add(goal.id);
                                  }
                                });
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF1A1D23) : const Color(0xFF0F1215),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF4EF4C0) : const Color(0xFF2A2D35),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          goal.title,
                                          style: TextStyle(
                                            color: isSelected ? const Color(0xFFF3F3F3) : const Color(0xFFCCCCCC),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (goal.description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            goal.description,
                                            style: const TextStyle(
                                              color: Color(0xFF888888),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF4EF4C0) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF4EF4C0) : const Color(0xFF888888),
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Color(0xFF0A0E12),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4EF4C0),
                          foregroundColor: const Color(0xFF0A0E12),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMoodButton(int level, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, level),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22.5),
        ),
        child: CustomPaint(
          painter: _MoodFacePainter(level),
        ),
      ),
    );
  }

  Widget _buildMarkdown(String text) {
    if (text.isEmpty) return const SizedBox.shrink();

    final lines = text.split('\n');
    int firstNonEmpty = 0;
    while (firstNonEmpty < lines.length && lines[firstNonEmpty].trim().isEmpty) {
      firstNonEmpty += 1;
    }

    String renderText = text;
    if (firstNonEmpty < lines.length) {
      final firstLine = lines[firstNonEmpty];
      final startsWithHeading = firstLine.trimLeft().startsWith('#');
      if (!startsWithHeading) {
        final before = lines.sublist(0, firstNonEmpty).join('\n');
        final after = lines.sublist(firstNonEmpty + 1).join('\n');
        final escapedFirst = firstLine;
        final buffer = StringBuffer();
        if (before.isNotEmpty) buffer.writeln(before);
        buffer.writeln('# $escapedFirst');
        if (after.isNotEmpty) buffer.writeln(after);
        renderText = buffer.toString();
      }
    }

    return MarkdownBody(
      data: renderText,
      selectable: false,
      styleSheet: MarkdownStyleSheet(
        a: const TextStyle(color: Color(0xFF4EF4C0)),
        p: const TextStyle(color: Color(0xFFF3F3F3), fontSize: 17, height: 1.6),
        h1: const TextStyle(color: Color(0xFFF3F3F3), fontSize: 22, fontWeight: FontWeight.bold),
        h2: const TextStyle(color: Color(0xFFF3F3F3), fontSize: 20, fontWeight: FontWeight.bold),
      ),
      onTapLink: (text, href, title) {
        if (href != null && href.startsWith('ref:')) {
          final id = href.substring(4);
          final e = JournalService.getById(id);
          if (e != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => JournalEntryScreen(entryId: e.id)));
          }
        }
      },
    );
  }

  void _wrapSelection(String left, String right) {
    final text = _controller.text;
    final sel = _controller.selection;
    final start = sel.start < 0 ? 0 : sel.start;
    final end = sel.end < 0 ? text.length : sel.end;
    final before = text.substring(0, start);
    final mid = text.substring(start, end);
    final after = text.substring(end);
    final newText = before + left + mid + right + after;
    final newOffset = start + left.length + mid.length + right.length;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    setState(() {});
  }

  void _insertHeading() {
    final text = _controller.text;
    final sel = _controller.selection;
    final pos = sel.start < 0 ? text.length : sel.start;
    final lineStart = text.lastIndexOf('\n', pos - 1) + 1;
    final before = text.substring(0, lineStart);
    final rest = text.substring(lineStart);
    final newText = '$before# $rest';
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + 2),
    );
    setState(() {});
  }

  void _insertLink() async {
    if (_pastEntries.isEmpty) await _loadPastEntries();
    if (!mounted) return;
    final picked = await showModalBottomSheet<JournalEntry?>(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 400,
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text('Insert link to an entry', style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _pastEntries.length,
                  itemBuilder: (context, index) {
                    final e = _pastEntries[index];
                    final preview = e.content.length > 60 ? '${e.content.substring(0, 60)}…' : e.content;
                    return ListTile(
                      title: Text(preview),
                      subtitle: Text(e.createdAt.toLocal().toString()),
                      onTap: () => Navigator.pop(context, e),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      final preview = picked.content.length > 30 ? '${picked.content.substring(0, 30)}…' : picked.content;
      final token = '[$preview](ref:${picked.id})';
      _insertTextAtSelection(token);
      if (!_linkedEntryIds.contains(picked.id)) _linkedEntryIds.add(picked.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
          color: const Color(0xFFF3F3F3),
        ),
        actions: [
          TextButton(
            onPressed: _saveEntry,
            child: const Text('Done', style: TextStyle(color: Color(0xFF4EF4C0), fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ResponsiveContainer(
              maxWidth: 900,
              child: Padding(
              padding: const EdgeInsets.only(top: 120, left: 20, right: 20, bottom: 80),
              child: Container(
                color: bgColor,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 200),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Stack(
                          children: [
                            if (_showPrompt && !_showFormatted)
                              Positioned(
                                left: 0,
                                top: 0,
                                right: 0,
                                child: IgnorePointer(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: _controller.text,
                                          style: const TextStyle(
                                            color: Colors.transparent,
                                            fontSize: 17,
                                            height: 1.6,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '  $_currentPrompt',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 17,
                                            height: 1.6,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            _showFormatted
                                ? _buildMarkdown(_controller.text)
                                : TextField(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    keyboardType: TextInputType.multiline,
                                    maxLines: null,
                                    style: const TextStyle(color: Color(0xFFF3F3F3), fontSize: 17, height: 1.6),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      filled: false,
                                      hintText: '',
                                    ),
                                    cursorColor: const Color(0xFF4EF4C0),
                                    onChanged: (_) => setState(() {}),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ),
          ),
          if (!isWeb)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              color: bgColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(onPressed: _insertBulletPoint, icon: const Icon(Icons.list, color: Color(0xFFF3F3F3))),
                  IconButton(onPressed: _insertLink, icon: const Icon(Icons.link, color: Color(0xFFF3F3F3))),
                  IconButton(onPressed: () => _wrapSelection('**', '**'), icon: const Icon(Icons.format_bold, color: Color(0xFFF3F3F3))),
                  IconButton(onPressed: _insertHeading, icon: const Icon(Icons.format_size, color: Color(0xFFF3F3F3))),
                  IconButton(
                    onPressed: () => setState(() => _showFormatted = !_showFormatted),
                    icon: Icon(
                      _showFormatted ? Icons.code : Icons.visibility,
                      color: const Color(0xFF4EF4C0),
                    ),
                    tooltip: _showFormatted ? 'Show raw markdown' : 'Show formatted',
                  ),
                  IconButton(
                    onPressed: _showGoalTagsPicker,
                    icon: Icon(
                      Icons.local_offer_outlined,
                      color: _selectedGoalTags.isNotEmpty ? const Color(0xFF4EF4C0) : const Color(0xFFF3F3F3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          if (!isWeb)
          Positioned(
            bottom: 70.0,
            right: 10.0,
            child: FloatingActionButton(
              heroTag: 'entryHelpFab',
              mini: true,
              backgroundColor: const Color(0xFF1E1F21),
              foregroundColor: const Color(0xFFF3F3F3),
              onPressed: _showMarkdownHelp,
              child: const Text(
                '?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0C0D0F)),
              ),
            ),
          ),
          if (isWeb)
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'markdownToggle',
                  mini: false,
                  backgroundColor: const Color(0xFF1E1F21),
                  foregroundColor: const Color(0xFF4EF4C0),
                  onPressed: () => setState(() => _showFormatted = !_showFormatted),
                  child: Icon(
                    _showFormatted ? Icons.code : Icons.visibility,
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'goalTagsFab',
                  mini: false,
                  backgroundColor: const Color(0xFF1E1F21),
                  foregroundColor: _selectedGoalTags.isNotEmpty ? const Color(0xFF4EF4C0) : const Color(0xFFF3F3F3),
                  onPressed: _showGoalTagsPicker,
                  child: const Icon(Icons.local_offer_outlined),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'entryHelpFab',
                  mini: false,
                  backgroundColor: const Color(0xFF1E1F21),
                  foregroundColor: const Color(0xFFF3F3F3),
                  onPressed: _showMarkdownHelp,
                  child: const Text(
                    '?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0C0D0F)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMarkdownHelp() {
    final sample = '''
  You can use Markdown in your entries. Below are explicit examples showing the *syntax* (in code) and what it renders as.

  **Bold**
  Syntax:
  ```
  **bold text**
  ```
  Renders as: **bold text**

  *Italic*
  Syntax:
  ```
  *italic text*
  ```
  Renders as: *italic text*

  Headings
  Syntax:
  ```
  # Heading 1
  ## Heading 2
  ```
  Renders as:
  # Heading 1
  ## Heading 2

  Lists
  Syntax:
  ```
  - First item
  - Second item
  ```

  Inline code and code blocks
  Inline syntax: `` `code` `` → renders as `code`
  Block syntax:
  ```
  print('hello world');
  ```

  Links
  Syntax:
  ```
  [Link text](https://example.com)
  ```
  Or to link to another entry in the app (use `ref:` scheme):
  ```
  [See entry](ref:ENTRY_ID)
  ```

  ''';

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Markdown Help', style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                child: SingleChildScrollView(
                  child: MarkdownBody(data: sample),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MoodFacePainter extends CustomPainter {
  final int level;

  _MoodFacePainter(this.level);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2A2D35)
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
