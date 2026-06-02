import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../features/radar/models/scout_scan_result.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionsRequested = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      defaultPresentAlert: true,
      defaultPresentBanner: true,
      defaultPresentBadge: true,
      defaultPresentList: true,
      defaultPresentSound: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    _initialized = true;
  }

  Future<void> ensurePermissions() async {
    await initialize();
    if (_permissionsRequested) {
      return;
    }

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    _permissionsRequested = true;
  }

  Future<void> showScanCompleteNotification(ScoutScanResult result) async {
    await ensurePermissions();

    final totalMatches = result.totalLeads;
    final body = _buildScanCompleteBody(
      totalMatches: totalMatches,
      location: result.request.location,
    );

    await _plugin.show(
      1001,
      'Scan complete',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scan_complete_channel',
          'Scan Complete',
          channelDescription:
              'Alerts when a lead scan finishes and matches are ready.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentBadge: true,
          presentList: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> showMorningReminder() async {
    await ensurePermissions();

    const reminders = [
      'You have leads waiting. Time to scout!',
      'Good morning! Your pipeline needs attention today.',
      'Rise and scout! There are businesses waiting for your pitch.',
      'New day, new leads. Check your radar!',
      'Your streak starts now. Open Scoutify and chase some leads!',
    ];

    final body = reminders[DateTime.now().millisecond % reminders.length];

    await _plugin.show(
      2001,
      'Morning Scout',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'morning_reminder_channel',
          'Morning Reminder',
          channelDescription: 'Daily morning reminders to check your leads.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentBadge: true,
          presentList: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> scheduleMorningReminder({int hour = 8, int minute = 0}) async {
    await ensurePermissions();

    await _plugin.zonedSchedule(
      3001,
      'Morning Scout',
      'You have leads waiting. Time to scout!',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'morning_reminder_channel',
          'Morning Reminder',
          channelDescription: 'Daily morning reminders to check your leads.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentBadge: true,
          presentList: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelMorningReminder() async {
    await _plugin.cancel(3001);
  }

  Future<void> showStreakNotification(int streak) async {
    await ensurePermissions();

    String title;
    String body;

    if (streak == 1) {
      title = 'Streak Started!';
      body = 'Day 1! You\'re on your way. Keep scouting daily.';
    } else if (streak == 3) {
      title = '3 Day Streak!';
      body = 'You\'re on fire! 3 days of consistent scouting.';
    } else if (streak == 7) {
      title = 'Week Warrior!';
      body = '7 days straight! You\'re a true scout master.';
    } else if (streak == 14) {
      title = '2 Week Streak!';
      body = '14 days of relentless lead hunting. Impressive!';
    } else if (streak == 30) {
      title = 'Monthly Champion!';
      body = '30 days! You\'ve built an unstoppable habit.';
    } else {
      title = '$streak Day Streak!';
      body = 'Keep it going! Your streak is growing stronger.';
    }

    await _plugin.show(
      4000 + streak,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_channel',
          'Streak Alerts',
          channelDescription: 'Notifications when your scout streak increases.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentBadge: true,
          presentList: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> showScanAlert({
    required String location,
    required int leadCount,
  }) async {
    await ensurePermissions();

    final title = 'New Leads in $location';
    final body = leadCount == 1
        ? '1 new business spotted. Check it out!'
        : '$leadCount new businesses spotted. Your radar is updated!';

    await _plugin.show(
      5001,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scan_alert_channel',
          'Scan Alerts',
          channelDescription: 'Alerts when new leads are found in your area.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentBadge: true,
          presentList: true,
          presentSound: true,
        ),
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  String _buildScanCompleteBody({
    required int totalMatches,
    required String location,
  }) {
    if (totalMatches <= 0) {
      return 'Your scan for $location is ready. No local businesses matched your filters this time.';
    }
    if (totalMatches == 1) {
      return 'Found 1 local business that matches your filters in $location. Open Radar to review it.';
    }
    return 'Found $totalMatches local businesses that match your filters in $location. Open Radar to review them.';
  }
}
