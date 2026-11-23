import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../data/lessons.dart';
import '../data/workspace_store.dart';
import '../services/voice_commands.dart';
import '../theme.dart';

/// Opens the voice assistant. [onNavigate] switches the bottom-nav tab.
Future<void> openVoiceAssistant(BuildContext context, WorkspaceStore store, void Function(int) onNavigate) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => VoiceSheet(store: store, onNavigate: onNavigate),
  );
}

class VoiceSheet extends StatefulWidget {
  const VoiceSheet({super.key, required this.store, required this.onNavigate});
  final WorkspaceStore store;
  final void Function(int) onNavigate;
  @override
  State<VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<VoiceSheet> {
  final speech = SpeechToText();
  final tts = FlutterTts();
  final text = TextEditingController();
  bool ready = false, listening = false, speak = true;
  String? status;
  VoiceAction? action;
  String? result;

  static const examples = [
    'I solved two sum',
    'Remind me to submit the paper tomorrow at 5 pm',
    'Add a CTF session on Friday at 7 pm for 90 minutes',
    'I did 3 LeetCode problems on graphs',
    'Worked on CROSSWITNESS literature review',
    'What have I done today?',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      ready = await speech.initialize(
        onStatus: (s) {
          if (!mounted) return;
          if (s == 'done' || s == 'notListening') setState(() => listening = false);
        },
        onError: (e) {
          if (mounted) setState(() {
            listening = false;
            status = e.errorMsg == 'error_no_match' ? 'Didn\'t catch that. Tap the mic and try again.' : 'Mic error: ${e.errorMsg}';
          });
        },
      );
      await tts.setSpeechRate(0.5);
    } catch (_) {
      ready = false;
    }
    if (mounted) {
      setState(() => status = ready ? 'Tap the mic and speak' : 'Voice input is unavailable on this phone. Type below instead.');
      if (ready) _listen();
    }
  }

  @override
  void dispose() {
    speech.stop();
    tts.stop();
    text.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    if (!ready) return;
    setState(() {
      listening = true;
      result = null;
      status = 'Listening…';
    });
    await speech.listen(
      onResult: (r) {
        if (!mounted) return;
        setState(() {
          text.text = r.recognizedWords;
          action = parseVoiceCommand(r.recognizedWords);
          if (r.finalResult) {
            listening = false;
            status = 'Check it, then tap Confirm';
          }
        });
      },
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(partialResults: true, cancelOnError: true),
    );
  }

  Future<void> _stop() async {
    await speech.stop();
    if (mounted) setState(() => listening = false);
  }

  void _parseTyped(String v) => setState(() {
        action = v.trim().isEmpty ? null : parseVoiceCommand(v);
        result = null;
      });

  Future<void> _say(String s) async {
    if (speak) {
      try {
        await tts.speak(s);
      } catch (_) {}
    }
  }

  Future<void> _confirm() async {
    final a = action;
    if (a == null) return;
    final store = widget.store;
    String reply;
    switch (a.intent) {
      case VoiceIntent.reminder:
        final due = a.data['dueAt'] as DateTime;
        await store.upsert({
          'id': newWorkspaceId(),
          'kind': 'reminder',
          'title': a.data['title'],
          'notes': 'Added by voice',
          'dueAt': due.toUtc().toIso8601String(),
          'done': false,
          'notificationId': DateTime.now().microsecondsSinceEpoch % 2000000000,
        });
        reply = 'Reminder set.';
      case VoiceIntent.schedule:
        await store.upsert({'id': newWorkspaceId(), 'kind': 'schedule', ...a.data});
        reply = 'Added to your timetable.';
      case VoiceIntent.solveLesson:
        final id = a.data['lessonId'];
        final lesson = lessons.firstWhere((l) => l.id == id);
        final current = store.ofKind('lesson').where((e) => e['id'] == id).firstOrNull ?? {};
        await store.upsert({
          ...current,
          'id': id,
          'kind': 'lesson',
          'title': lesson.title,
          'area': lesson.area,
          'done': true,
          'doneAt': DateTime.now().toUtc().toIso8601String(),
          'confidence': current['confidence'] ?? 'ok',
        });
        reply = 'Nice. ${lesson.title} is marked as solved.';
      case VoiceIntent.log:
      case VoiceIntent.note:
        await store.upsert({
          'id': newWorkspaceId(),
          'kind': 'log',
          'category': a.data['category'] ?? 'Note',
          'project': a.data['project'],
          'title': a.data['title'],
          'note': 'Added by voice',
          'loggedAt': DateTime.now().toUtc().toIso8601String(),
        });
        reply = a.intent == VoiceIntent.note ? 'Saved as a note.' : 'Logged.';
      case VoiceIntent.summary:
        reply = progressSummary(store, week: a.data['range'] == 'week');
      case VoiceIntent.navigate:
        widget.onNavigate(a.tab ?? 0);
        if (mounted) Navigator.pop(context);
        return;
      case VoiceIntent.unknown:
        return;
    }
    if (a.tab != null && a.intent != VoiceIntent.summary) widget.onNavigate(a.tab!);
    if (!mounted) return;
    setState(() {
      result = reply;
      action = null;
      text.clear();
      status = 'Done. Tap the mic for another command.';
    });
    _say(reply);
  }

  @override
  Widget build(BuildContext context) {
    final a = action;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Text('Voice assistant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(
              tooltip: speak ? 'Mute replies' : 'Speak replies',
              onPressed: () => setState(() => speak = !speak),
              icon: Icon(speak ? Icons.volume_up : Icons.volume_off, color: AppColors.muted),
            ),
          ]),
          const SizedBox(height: 4),
          Text(status ?? 'Starting…', style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 18),
          Center(
            child: GestureDetector(
              onTap: listening ? _stop : _listen,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: listening ? 96 : 84,
                height: listening ? 96 : 84,
                decoration: BoxDecoration(
                  color: listening ? AppColors.danger : AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (listening ? AppColors.danger : AppColors.primary).withValues(alpha: 0.3),
                      blurRadius: listening ? 28 : 12,
                      spreadRadius: listening ? 6 : 0,
                    ),
                  ],
                ),
                child: Icon(listening ? Icons.stop_rounded : Icons.mic, color: Colors.white, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: text,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            onChanged: _parseTyped,
            decoration: const InputDecoration(hintText: 'Or type a command…', prefixIcon: Icon(Icons.keyboard_outlined)),
          ),
          if (a != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Icon(_iconFor(a.intent), color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(a.summary, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4))),
              ]),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: a.intent == VoiceIntent.unknown ? null : _confirm,
              icon: const Icon(Icons.check),
              label: Text(a.intent == VoiceIntent.summary ? 'Show' : 'Confirm'),
            ),
          ],
          if (result != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(16)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(child: Text(result!, style: const TextStyle(height: 1.45))),
              ]),
            ),
          ],
          const SizedBox(height: 18),
          const Text('Try saying', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in examples)
              ActionChip(
                label: Text(e, style: const TextStyle(fontSize: 12.5)),
                onPressed: () {
                  text.text = e;
                  _parseTyped(e);
                },
              ),
          ]),
        ]),
      ),
    );
  }

  IconData _iconFor(VoiceIntent i) => switch (i) {
        VoiceIntent.reminder => Icons.alarm_add,
        VoiceIntent.schedule => Icons.event_available,
        VoiceIntent.solveLesson => Icons.school,
        VoiceIntent.log => Icons.edit_note,
        VoiceIntent.note => Icons.sticky_note_2_outlined,
        VoiceIntent.summary => Icons.insights,
        VoiceIntent.navigate => Icons.open_in_new,
        VoiceIntent.unknown => Icons.help_outline,
      };
}

bool _inRange(dynamic iso, DateTime from) {
  final d = DateTime.tryParse(iso?.toString() ?? '')?.toLocal();
  return d != null && !d.isBefore(from);
}

/// Everything done today (or this week), as a short spoken-friendly paragraph.
String progressSummary(WorkspaceStore store, {bool week = false}) {
  final now = DateTime.now();
  final from = week
      ? DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1))
      : DateTime(now.year, now.month, now.day);
  final solved = store.ofKind('lesson').where((e) => e['done'] == true && _inRange(e['doneAt'], from)).toList();
  final logs = store.ofKind('log').where((e) => _inRange(e['loggedAt'] ?? e['updatedAt'], from)).toList();
  final count = <String, int>{};
  for (final l in logs) {
    count[l['category']?.toString() ?? 'Note'] = (count[l['category']?.toString() ?? 'Note'] ?? 0) + 1;
  }
  final pending = store.ofKind('reminder').where((e) => e['done'] != true).length;
  final period = week ? 'This week' : 'Today';
  if (solved.isEmpty && logs.isEmpty) {
    return '$period you haven\'t logged anything yet. You have $pending open reminders. Try solving one study topic.';
  }
  final parts = <String>[];
  if (solved.isNotEmpty) parts.add('solved ${solved.length} topic${solved.length == 1 ? '' : 's'} (${solved.map((e) => e['title']).take(3).join(', ')})');
  count.forEach((k, v) => parts.add('$v $k ${v == 1 ? 'entry' : 'entries'}'));
  return '$period you ${parts.join(', ')}. $pending reminder${pending == 1 ? '' : 's'} still open.';
}
