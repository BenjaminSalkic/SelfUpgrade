import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'journal_service.dart';
import 'goal_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const int dailyReminderID = 1;
  static const int streakReminderID = 2;
  static const int sundayReviewID = 3;
  static const int smartReminderID = 4;
  static const int goalReminderID = 5;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    
    final String timeZoneName = await _getTimeZone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  static Future<String> _getTimeZone() async {
    try {
      return DateTime.now().timeZoneName;
    } catch (e) {
      return 'UTC';
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
  }

  static Future<bool> requestPermissions() async {
    final bool? result = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return result ?? false;
  }

  static Future<void> scheduleDailyReminder({int? hour, int? minute}) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_daily_enabled') ?? true;
    
    if (!enabled) return;

    final reminderHour = hour ?? prefs.getInt('notifications_daily_hour') ?? 20;
    final reminderMinute = minute ?? prefs.getInt('notifications_daily_minute') ?? 0;

    await _notifications.zonedSchedule(
      dailyReminderID,
      '📝 Time to write!',
      'How was your day? Take a moment to reflect.',
      _nextInstanceOfTime(reminderHour, reminderMinute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Journal Reminder',
          channelDescription: 'Daily reminder to write in your journal',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleSundayReview({int? hour, int? minute}) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_sunday_enabled') ?? true;
    
    if (!enabled) return;

    final reviewHour = hour ?? prefs.getInt('notifications_sunday_hour') ?? 17;
    final reviewMinute = minute ?? prefs.getInt('notifications_sunday_minute') ?? 0;

    await _notifications.zonedSchedule(
      sundayReviewID,
      'Weekly Review Time!',
      'What were your biggest wins this week?',
      _nextInstanceOfSunday(reviewHour, reviewMinute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sunday_review',
          'Sunday Weekly Review',
          channelDescription: 'Weekly reflection reminder every Sunday',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> scheduleGoalReminder({int? hour, int? minute}) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_goal_enabled') ?? true;
    
    if (!enabled) return;

    final goalHour = hour ?? prefs.getInt('notifications_goal_hour') ?? 9;
    final goalMinute = minute ?? prefs.getInt('notifications_goal_minute') ?? 0;

    final goals = GoalService.getActive();
    if (goals.isEmpty) return;

    final goalTitle = goals.first.title;

    await _notifications.zonedSchedule(
      goalReminderID,
      '🎯 Goal Check-in',
      'How\'s your progress on "$goalTitle"?',
      _nextInstanceOfTime(goalHour, goalMinute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_reminder',
          'Goal Reminders',
          channelDescription: 'Reminders to work on your goals',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> checkAndScheduleStreakReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_streak_enabled') ?? true;
    
    if (!enabled) return;

    final entries = JournalService.getAll();
    if (entries.isEmpty) return;

    int streak = 0;
    final today = DateTime.now();
    var checkDate = DateTime(today.year, today.month, today.day);

    while (true) {
      final hasEntry = entries.any((e) {
        final entryDate = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
        return entryDate.isAtSameMomentAs(checkDate);
      });

      if (hasEntry) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    if (streak >= 3) {
      await _notifications.show(
        streakReminderID,
        '🔥 $streak Day Streak!',
        'You\'re on fire! Don\'t break your streak today!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'streak_reminder',
            'Streak Notifications',
            channelDescription: 'Celebrate and maintain your journaling streak',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  static Future<void> scheduleSmartReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_smart_enabled') ?? true;
    
    if (!enabled) return;

    final entries = JournalService.getAll();
    if (entries.isEmpty) return;

    final lastEntry = entries.first;
    final daysSinceLastEntry = DateTime.now().difference(lastEntry.createdAt).inDays;

    if (daysSinceLastEntry >= 2) {
      await _notifications.show(
        smartReminderID,
        '💭 We miss you!',
        'It\'s been $daysSinceLastEntry days. How have you been?',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'smart_reminder',
            'Smart Reminders',
            channelDescription: 'Reminders when you haven\'t journaled in a while',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static tz.TZDateTime _nextInstanceOfSunday(int hour, int minute) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != DateTime.sunday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static Future<void> scheduleAll() async {
    await initialize();
    
    final prefs = await SharedPreferences.getInstance();
    
    final dailyHour = prefs.getInt('notifications_daily_hour') ?? 20;
    final dailyMinute = prefs.getInt('notifications_daily_minute') ?? 0;
    final sundayHour = prefs.getInt('notifications_sunday_hour') ?? 17;
    final sundayMinute = prefs.getInt('notifications_sunday_minute') ?? 0;
    final goalHour = prefs.getInt('notifications_goal_hour') ?? 9;
    final goalMinute = prefs.getInt('notifications_goal_minute') ?? 0;
    
    await cancelAll();
    
    await scheduleDailyReminder(hour: dailyHour, minute: dailyMinute);
    await scheduleSundayReview(hour: sundayHour, minute: sundayMinute);
    await scheduleGoalReminder(hour: goalHour, minute: goalMinute);
    await checkAndScheduleStreakReminder();
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  static Future<void> updatePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    await scheduleAll();
  }
}
