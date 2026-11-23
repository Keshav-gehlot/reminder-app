import 'package:flutter_test/flutter_test.dart';
import 'package:cybertrack12/services/voice_commands.dart';

void main() {
  // Tuesday 24 Nov 2026, 10:00.
  final now = DateTime(2026, 11, 24, 10, 0);

  test('reminder with day and time', () {
    final a = parseVoiceCommand('Remind me to submit the paper tomorrow at 5 pm', now: now);
    expect(a.intent, VoiceIntent.reminder);
    expect(a.data['title'], 'Submit the paper');
    expect(a.data['dueAt'], DateTime(2026, 11, 25, 17, 0));
  });

  test('relative reminder', () {
    final a = parseVoiceCommand('remind me to drink water in 30 minutes', now: now);
    expect(a.intent, VoiceIntent.reminder);
    expect(a.data['dueAt'], DateTime(2026, 11, 24, 10, 30));
  });

  test('timetable session', () {
    final a = parseVoiceCommand('Add a CTF study session on Friday at 7 pm for 90 minutes', now: now);
    expect(a.intent, VoiceIntent.schedule);
    expect(a.data['day'], 'Friday');
    expect(a.data['startTime'], '19:00');
    expect(a.data['duration'], 90);
    expect(a.data['subject'], 'CTF');
  });

  test('solved a lesson', () {
    final a = parseVoiceCommand('I solved two sum', now: now);
    expect(a.intent, VoiceIntent.solveLesson);
    expect(a.data['lessonId'], 'lesson-arrays-and-hash-maps');
  });

  test('finished a CTF topic by keyword', () {
    final a = parseVoiceCommand('I finished the SQL injection lesson', now: now);
    expect(a.intent, VoiceIntent.solveLesson);
  });

  test('practice log', () {
    final a = parseVoiceCommand('I did 3 leetcode problems on graphs', now: now);
    expect(a.intent, VoiceIntent.log);
    expect(a.data['category'], 'LeetCode');
  });

  test('ctf log', () {
    final a = parseVoiceCommand('Completed a TryHackMe room on Burp Suite', now: now);
    expect(a.intent, VoiceIntent.log);
    expect(a.data['category'], 'CTF');
  });

  test('research log with project', () {
    final a = parseVoiceCommand('Worked on the CROSSWITNESS literature review', now: now);
    expect(a.intent, VoiceIntent.log);
    expect(a.data['category'], 'Research');
    expect(a.data['project'], 'CROSSWITNESS');
  });

  test('summary', () {
    expect(parseVoiceCommand('What have I done today?', now: now).intent, VoiceIntent.summary);
    expect(parseVoiceCommand('show my progress this week', now: now).data['range'], 'week');
  });

  test('navigation', () {
    final a = parseVoiceCommand('Open study', now: now);
    expect(a.intent, VoiceIntent.navigate);
    expect(a.tab, 1);
  });

  test('fallback note', () {
    expect(parseVoiceCommand('buy a new keyboard', now: now).intent, VoiceIntent.note);
  });
}
