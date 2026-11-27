import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the last few uncaught errors on the device so they can be attached
/// to a bug report. Nothing is sent anywhere automatically.
class CrashLog {
  static const _key = 'cybertrack_crash_log';
  static const _max = 15;
  static SharedPreferences? _prefs;

  static Future<void> install() async {
    _prefs = await SharedPreferences.getInstance();
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      record(details.exceptionAsString(), details.stack);
      previous?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error.toString(), stack);
      return false; // let the default handler log it too
    };
  }

  static void record(String error, StackTrace? stack) {
    final prefs = _prefs;
    if (prefs == null) return;
    final list = entries();
    list.insert(0, {
      'at': DateTime.now().toIso8601String(),
      'error': error.length > 600 ? error.substring(0, 600) : error,
      'stack': (stack?.toString() ?? '').split('\n').take(8).join('\n'),
    });
    prefs.setString(_key, jsonEncode(list.take(_max).toList()));
  }

  static List<Map<String, dynamic>> entries() {
    final raw = _prefs?.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clear() async => _prefs?.remove(_key);

  /// GitHub "new issue" link with the latest errors pre-filled.
  static Uri reportUrl({String version = ''}) {
    final recent = entries().take(3).map((e) => '**${e['at']}**\n```\n${e['error']}\n${e['stack']}\n```').join('\n\n');
    final body = StringBuffer()
      ..writeln('**What happened?**\n\n<describe what you were doing>\n')
      ..writeln('**App build:** $version')
      ..writeln('**Platform:** ${defaultTargetPlatform.name}\n')
      ..writeln(recent.isEmpty ? '_No crashes recorded on this device._' : '**Recent errors (on-device log):**\n\n$recent');
    var text = body.toString();
    if (text.length > 6000) text = text.substring(0, 6000);
    return Uri.https('github.com', '/Keshav-gehlot/reminder-app/issues/new', {
      'title': 'Bug: ',
      'labels': 'bug',
      'body': text,
    });
  }
}
