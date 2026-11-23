import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  int _notificationId(Map<String, dynamic> reminder) {
    final saved = reminder['notificationId'];
    if (saved is int) return saved;
    return (reminder['id']?.toString().hashCode ?? 0) & 0x7fffffff;
  }

  Future<void> _requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<void> schedule(Map<String, dynamic> reminder) async {
    if (!_initialized ||
        reminder['done'] == true ||
        reminder['deleted'] == true) {
      return;
    }

    final value = reminder['dueAt'];
    final due = value is String ? DateTime.tryParse(value) : null;
    if (due == null || !due.isAfter(DateTime.now())) return;

    await _requestPermission();
    await _plugin.zonedSchedule(
      id: _notificationId(reminder),
      title: reminder['title']?.toString() ?? 'CyberTrack reminder',
      body: reminder['notes']?.toString() ?? 'You have a reminder due.',
      scheduledDate: tz.TZDateTime.from(due, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'cybertrack_reminders',
          'CyberTrack reminders',
          channelDescription: 'Study reminders and research deadlines',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: reminder['id']?.toString(),
    );
  }

  Future<void> cancel(Map<String, dynamic> reminder) async {
    if (!_initialized) return;
    await _plugin.cancel(id: _notificationId(reminder));
  }

  Future<void> rescheduleAll(List<Map<String, dynamic>> items) async {
    if (!_initialized) return;
    await _plugin.cancelAll();
    for (final item in items) {
      if (item['kind'] == 'reminder') {
        await schedule(item);
      }
    }
  }
}
