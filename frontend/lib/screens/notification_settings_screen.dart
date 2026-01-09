import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../theme/gradient_background.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _dailyEnabled = true;
  bool _sundayEnabled = true;
  bool _goalEnabled = true;
  bool _streakEnabled = true;
  bool _smartEnabled = true;
  
  int _dailyHour = 20;
  int _dailyMinute = 0;
  int _sundayHour = 17;
  int _sundayMinute = 0;
  int _goalHour = 9;
  int _goalMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyEnabled = prefs.getBool('notifications_daily_enabled') ?? true;
      _sundayEnabled = prefs.getBool('notifications_sunday_enabled') ?? true;
      _goalEnabled = prefs.getBool('notifications_goal_enabled') ?? true;
      _streakEnabled = prefs.getBool('notifications_streak_enabled') ?? true;
      _smartEnabled = prefs.getBool('notifications_smart_enabled') ?? true;
      
      _dailyHour = prefs.getInt('notifications_daily_hour') ?? 20;
      _dailyMinute = prefs.getInt('notifications_daily_minute') ?? 0;
      _sundayHour = prefs.getInt('notifications_sunday_hour') ?? 17;
      _sundayMinute = prefs.getInt('notifications_sunday_minute') ?? 0;
      _goalHour = prefs.getInt('notifications_goal_hour') ?? 9;
      _goalMinute = prefs.getInt('notifications_goal_minute') ?? 0;
    });
  }

  Future<void> _saveAndReschedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_daily_enabled', _dailyEnabled);
    await prefs.setBool('notifications_sunday_enabled', _sundayEnabled);
    await prefs.setBool('notifications_goal_enabled', _goalEnabled);
    await prefs.setBool('notifications_streak_enabled', _streakEnabled);
    await prefs.setBool('notifications_smart_enabled', _smartEnabled);
    
    await prefs.setInt('notifications_daily_hour', _dailyHour);
    await prefs.setInt('notifications_daily_minute', _dailyMinute);
    await prefs.setInt('notifications_sunday_hour', _sundayHour);
    await prefs.setInt('notifications_sunday_minute', _sundayMinute);
    await prefs.setInt('notifications_goal_hour', _goalHour);
    await prefs.setInt('notifications_goal_minute', _goalMinute);
    
    await NotificationService.scheduleAll();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification settings saved'),
          backgroundColor: Color(0xFF4EF4C0),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _selectTime(BuildContext context, String type) async {
    int currentHour = 20;
    int currentMinute = 0;
    
    if (type == 'daily') {
      currentHour = _dailyHour;
      currentMinute = _dailyMinute;
    } else if (type == 'sunday') {
      currentHour = _sundayHour;
      currentMinute = _sundayMinute;
    } else if (type == 'goal') {
      currentHour = _goalHour;
      currentMinute = _goalMinute;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4EF4C0),
              onPrimary: Color(0xFF0A0E12),
              surface: Color(0xFF0A0E10),
              onSurface: Color(0xFFF3F3F3),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (type == 'daily') {
          _dailyHour = picked.hour;
          _dailyMinute = picked.minute;
        } else if (type == 'sunday') {
          _sundayHour = picked.hour;
          _sundayMinute = picked.minute;
        } else if (type == 'goal') {
          _goalHour = picked.hour;
          _goalMinute = picked.minute;
        }
      });
      await _saveAndReschedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: const Color(0xFF0A0E12),
      ),
      body: GradientBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 24),
            
            _buildNotificationTile(
              icon: Icons.edit_note,
              title: 'Daily Journal Reminder',
              subtitle: 'Get reminded to write every day',
              enabled: _dailyEnabled,
              time: _formatTime(_dailyHour, _dailyMinute),
              onChanged: (value) async {
                setState(() => _dailyEnabled = value);
                await _saveAndReschedule();
              },
              onTimeTap: () => _selectTime(context, 'daily'),
            ),
            
            const SizedBox(height: 16),
            
            _buildNotificationTile(
              icon: Icons.calendar_today,
              title: 'Sunday Weekly Review',
              subtitle: 'Reflect on your week every Sunday',
              enabled: _sundayEnabled,
              time: _formatTime(_sundayHour, _sundayMinute),
              onChanged: (value) async {
                setState(() => _sundayEnabled = value);
                await _saveAndReschedule();
              },
              onTimeTap: () => _selectTime(context, 'sunday'),
            ),
            
            const SizedBox(height: 16),
            
            _buildNotificationTile(
              icon: Icons.flag,
              title: 'Goal Check-in',
              subtitle: 'Daily reminder about your goals',
              enabled: _goalEnabled,
              time: _formatTime(_goalHour, _goalMinute),
              onChanged: (value) async {
                setState(() => _goalEnabled = value);
                await _saveAndReschedule();
              },
              onTimeTap: () => _selectTime(context, 'goal'),
            ),
            
            const SizedBox(height: 16),
            
            _buildNotificationTile(
              icon: Icons.local_fire_department,
              title: 'Streak Notifications',
              subtitle: 'Celebrate your journaling streaks',
              enabled: _streakEnabled,
              onChanged: (value) async {
                setState(() => _streakEnabled = value);
                await _saveAndReschedule();
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildNotificationTile(
              icon: Icons.psychology,
              title: 'Smart Reminders',
              subtitle: 'Get notified if you haven\'t journaled in a while',
              enabled: _smartEnabled,
              onChanged: (value) async {
                setState(() => _smartEnabled = value);
                await _saveAndReschedule();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    String? time,
    required ValueChanged<bool> onChanged,
    VoidCallback? onTimeTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? const Color(0xFF4EF4C0).withOpacity(0.3) : const Color(0xFF2A2D35),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(icon, color: enabled ? const Color(0xFF4EF4C0) : const Color(0xFF888888)),
            title: Text(
              title,
              style: TextStyle(
                color: enabled ? const Color(0xFFF3F3F3) : const Color(0xFF888888),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 13,
              ),
            ),
            value: enabled,
            onChanged: onChanged,
            activeColor: const Color(0xFF4EF4C0),
          ),
          if (time != null && enabled)
            InkWell(
              onTap: onTimeTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF2A2D35), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 20, color: Color(0xFF4EF4C0)),
                    const SizedBox(width: 12),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFFF3F3F3),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Color(0xFF888888)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}
