import '../data/lessons.dart';

/// What a spoken (or typed) sentence asks the app to do.
enum VoiceIntent { completeReminder, solveLesson, reminder, schedule, log, summary, navigate, note, unknown }

class VoiceAction {
  VoiceAction(this.intent, this.summary, {this.data = const {}, this.tab});
  final VoiceIntent intent;

  /// Human-readable description shown before confirming.
  final String summary;
  final Map<String, dynamic> data;

  /// Bottom-nav tab to open: 0 Home, 1 Study, 2 Plan, 3 Track.
  final int? tab;
}

const projectNames = ['LeakTrace + ECDAT', 'CROSSWITNESS', 'Network Attack Forecasting', 'Bluetooth Music Middleware'];
const _days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
const _numberWords = {
  'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6, 'seven': 7, 'eight': 8,
  'nine': 9, 'ten': 10, 'eleven': 11, 'twelve': 12, 'fifteen': 15, 'twenty': 20, 'thirty': 30,
  'forty five': 45, 'forty-five': 45, 'half an': 30, 'an': 1, 'a': 1,
};

String _norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r"[^a-z0-9:+\s'-]"), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Parses a sentence into an action. Pure function so it is easy to test.
VoiceAction parseVoiceCommand(String raw, {DateTime? now}) {
  final t = _norm(raw);
  now ??= DateTime.now();
  if (t.isEmpty) return VoiceAction(VoiceIntent.unknown, 'I did not catch that. Try again.');

  // 1. Summary / progress questions.
  if (RegExp(r'\b(what (have|did) i (do|done|finish|complete)|summary|my progress|how am i doing|what.s left|what is left|status)\b').hasMatch(t)) {
    final week = t.contains('week');
    return VoiceAction(VoiceIntent.summary, week ? 'Show this week\'s progress' : 'Show today\'s progress', data: {'range': week ? 'week' : 'today'});
  }

  // 2. Navigation.
  final nav = RegExp(r'^(open|go to|show|take me to|switch to)\s+(the\s+)?(home|study|lessons?|plan|timetable|schedule|reminders?|track|practice|research|news)\b').firstMatch(t);
  if (nav != null) {
    final target = nav.group(3)!;
    final tab = switch (target) {
      'home' || 'news' => 0,
      'study' || 'lesson' || 'lessons' => 1,
      'plan' || 'timetable' || 'schedule' || 'reminder' || 'reminders' => 2,
      _ => 3,
    };
    return VoiceAction(VoiceIntent.navigate, 'Open ${_capitalize(target)}', tab: tab);
  }

  // 3. Reminders.
  final rem = RegExp(r'^(please\s+)?(remind me( to)?|add (a )?reminder( to)?|set (a )?reminder( to)?|create (a )?reminder( to)?)\s+(.*)$').firstMatch(t);
  if (rem != null) {
    final rest = rem.group(10) ?? '';
    final when = _parseWhen(rest, now) ?? now.add(const Duration(hours: 1));
    final title = _capitalize(_stripTimeWords(rest));
    return VoiceAction(
      VoiceIntent.reminder,
      'Reminder: "${title.isEmpty ? 'Reminder' : title}" on ${_fmtDateTime(when)}',
      data: {'title': title.isEmpty ? 'Reminder' : title, 'dueAt': when},
      tab: 2,
    );
  }

  // 3b. Completing a reminder: "mark the paper reminder done", "I finished the reminder to call mom".
  final doneRem = RegExp(r'\breminder\b').hasMatch(t) && RegExp(r'\b(done|complete|completed|finished|tick|check off)\b').hasMatch(t);
  if (doneRem) {
    final words = t
        .replaceAll(RegExp(r'\b(mark|the|reminder|reminders|as|done|complete|completed|finished|i|to|tick|check|off|my|a)\b'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return VoiceAction(VoiceIntent.completeReminder, 'Mark reminder matching "${words.isEmpty ? 'latest' : words}" as done',
        data: {'query': words}, tab: 2);
  }

  // 4. Timetable sessions.
  if (RegExp(r'\b(add|create|schedule|plan|book)\b.*\b(session|study|class|slot|block)\b').hasMatch(t) ||
      RegExp(r'^(schedule|plan)\b').hasMatch(t)) {
    final day = _days.firstWhere((d) => t.contains(d), orElse: () {
      if (t.contains('tomorrow')) return _days[now!.add(const Duration(days: 1)).weekday - 1];
      return _days[now!.weekday - 1];
    });
    final time = _parseClock(t) ?? '18:00';
    final minutes = _parseDuration(t) ?? 60;
    final subject = _subjectOf(t);
    final title = '$subject session';
    return VoiceAction(
      VoiceIntent.schedule,
      'Timetable: $title, ${_capitalize(day)} at $time for $minutes min',
      data: {'title': title, 'day': _capitalize(day), 'startTime': time, 'duration': minutes, 'subject': subject},
      tab: 2,
    );
  }

  // 5. Solved / finished a study topic.
  final solvedVerb = RegExp(r'\b(solved|completed|finished|done with|learned|learnt|studied|mark(ed)?)\b').hasMatch(t);
  if (solvedVerb) {
    final lesson = matchLesson(t);
    if (lesson != null) {
      return VoiceAction(VoiceIntent.solveLesson, 'Mark "${lesson.title}" as solved', data: {'lessonId': lesson.id}, tab: 1);
    }
  }

  // 6. Practice / research logs.
  final logVerb = RegExp(r'\b(log|i did|i solved|solved|did|practiced|practised|completed|finished|worked on|working on|attempted|submitted|wrote|read)\b').hasMatch(t);
  final category = _categoryOf(t);
  if (logVerb && category != null) {
    final project = category == 'Research' ? _projectOf(t) : null;
    final title = _capitalize(t.replaceFirst(RegExp(r'^(log|i did|i|today i)\s+'), ''));
    return VoiceAction(
      VoiceIntent.log,
      'Log $category${project != null ? ' · $project' : ''}: "$title"',
      data: {'category': category, 'project': project, 'title': title},
      tab: 3,
    );
  }

  // 7. Fallback: offer to save it as a note in the practice log.
  return VoiceAction(VoiceIntent.note, 'Save as a note: "${_capitalize(t)}"', data: {'title': _capitalize(t)}, tab: 3);
}

/// Finds the study topic a sentence talks about, by keyword overlap.
Lesson? matchLesson(String text) {
  final t = _norm(text);
  const aliases = {
    'two sum': 'Arrays and hash maps', 'hash map': 'Arrays and hash maps', 'hashmap': 'Arrays and hash maps',
    'sql': 'Web: SQL injection', 'xss': 'Web: cross-site scripting (XSS)', 'cross site': 'Web: cross-site scripting (XSS)',
    'pcap': 'Network: PCAP triage', 'wireshark': 'Network: PCAP triage', 'magic bytes': 'Forensics: file signatures',
    'file signature': 'Forensics: file signatures', 'xor': 'Crypto: XOR', 'ghidra': 'Reverse engineering basics',
    'reverse engineering': 'Reverse engineering basics', 'recon': 'Web: reconnaissance and HTTP', 'privilege': 'Linux permissions',
    'linux': 'Linux permissions', 'dp': 'Dynamic programming', 'climbing stairs': 'Dynamic programming',
    'lcs': '2D dynamic programming', 'common subsequence': '2D dynamic programming', 'islands': 'Grid graphs',
    'dijkstra': 'Shortest paths: Dijkstra', 'trie': 'Tries (prefix trees)', 'bst': 'Binary search trees',
    'heap': 'Heaps and priority queues', 'big o': 'Big-O and complexity', 'complexity': 'Big-O and complexity',
    'cnn': 'Convolutional networks (CNNs)', 'transformer': 'Transformers and LLMs', 'llm': 'Transformers and LLMs',
    'backprop': 'Backpropagation', 'k means': 'K-means clustering', 'kmeans': 'K-means clustering',
    'regression': 'Linear regression', 'bias': 'Evaluating models', 'overfitting': 'Evaluating models',
    'bits': 'Bit manipulation', 'union find': 'Union-find', 'topological': 'Topological sort', 'merge sort': 'Sorting: merge sort',
  };
  for (final e in aliases.entries) {
    if (RegExp('\\b${RegExp.escape(e.key)}\\b').hasMatch(t)) {
      for (final l in lessons) {
        if (l.title == e.value) return l;
      }
    }
  }
  Lesson? best;
  var bestScore = 0.0;
  for (final l in lessons) {
    final words = _norm(l.title).split(' ').where((w) => w.length > 2 && !const {'and', 'the', 'web', 'basics'}.contains(w)).toList();
    if (words.isEmpty) continue;
    final hits = words.where((w) => t.contains(w)).length;
    final score = hits / words.length;
    if (hits > 0 && score > bestScore) {
      bestScore = score;
      best = l;
    }
  }
  return bestScore >= 0.5 ? best : null;
}

String? _categoryOf(String t) {
  if (RegExp(r'\b(ctf|picoctf|tryhackme|try hack me|hack the box|htb|hackthebox|flag|room|box|exploit|pwn|forensics challenge)\b').hasMatch(t)) return 'CTF';
  if (RegExp(r'\b(contest|codeforces|codechef|atcoder|weekly contest|biweekly)\b').hasMatch(t)) return 'Contest';
  if (RegExp(r'\b(leetcode|leet code|dsa|problem|problems|question|questions|neetcode)\b').hasMatch(t)) return 'LeetCode';
  if (RegExp(r'\b(research|paper|literature|experiment|leaktrace|leak trace|ecdat|crosswitness|cross witness|forecasting|bluetooth|middleware|thesis|draft)\b').hasMatch(t)) return 'Research';
  return null;
}

String? _projectOf(String t) {
  if (RegExp(r'leak ?trace|ecdat').hasMatch(t)) return projectNames[0];
  if (RegExp(r'cross ?witness').hasMatch(t)) return projectNames[1];
  if (RegExp(r'forecast|network attack').hasMatch(t)) return projectNames[2];
  if (RegExp(r'bluetooth|middleware|music').hasMatch(t)) return projectNames[3];
  return null;
}

String _subjectOf(String t) {
  if (RegExp(r'\b(ctf|hacking|security|tryhackme|htb|picoctf)\b').hasMatch(t)) return 'CTF';
  if (RegExp(r'\b(ai|ml|machine learning|deep learning)\b').hasMatch(t)) return 'AI/ML';
  if (RegExp(r'\b(research|paper)\b').hasMatch(t)) return 'Research';
  if (RegExp(r'\b(revision|revise)\b').hasMatch(t)) return 'Revision';
  if (RegExp(r'\b(contest)\b').hasMatch(t)) return 'Contest';
  return 'DSA';
}

int? _num(String s) => int.tryParse(s) ?? _numberWords[s];

/// "at 5 pm", "at 17:30", "at 7", "5:15 am" → "HH:MM".
String? _parseClock(String t) {
  final m = RegExp(r'\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm|a m|p m)?\b').allMatches(t).where((m) {
    final hasAt = t.substring(0, m.start).trimRight().endsWith('at') || m.group(0)!.startsWith('at');
    return m.group(3) != null || m.group(2) != null || hasAt;
  }).toList();
  if (m.isEmpty) {
    if (t.contains('noon')) return '12:00';
    if (t.contains('evening') || t.contains('tonight')) return '19:00';
    if (t.contains('morning')) return '09:00';
    if (t.contains('afternoon')) return '15:00';
    return null;
  }
  final g = m.first;
  var h = int.parse(g.group(1)!);
  final min = int.tryParse(g.group(2) ?? '0') ?? 0;
  final ap = (g.group(3) ?? '').replaceAll(' ', '');
  if (ap == 'pm' && h < 12) h += 12;
  if (ap == 'am' && h == 12) h = 0;
  if (ap.isEmpty && h >= 1 && h <= 7) h += 12; // "at 7" usually means evening for study plans
  if (h > 23 || min > 59) return null;
  return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
}

/// "for 90 minutes", "for 2 hours", "for an hour", "for half an hour".
int? _parseDuration(String t) {
  final m = RegExp(r'for\s+(\d+|one|two|three|four|five|ten|fifteen|twenty|thirty|forty five|forty-five|half an|an|a)\s*(minutes?|mins?|hours?|hrs?)').firstMatch(t);
  if (m == null) return null;
  final n = _num(m.group(1)!) ?? 1;
  return m.group(2)!.startsWith('h') ? (m.group(1) == 'half an' ? 30 : n * 60) : n;
}

DateTime? _parseWhen(String t, DateTime now) {
  final rel = RegExp(r'\bin\s+(\d+|one|two|three|four|five|ten|fifteen|twenty|thirty|an|a|half an)\s*(minutes?|mins?|hours?|hrs?|days?)\b').firstMatch(t);
  if (rel != null) {
    final n = _num(rel.group(1)!) ?? 1;
    final unit = rel.group(2)!;
    if (unit.startsWith('d')) return now.add(Duration(days: n));
    if (unit.startsWith('h')) return now.add(rel.group(1) == 'half an' ? const Duration(minutes: 30) : Duration(hours: n));
    return now.add(Duration(minutes: n));
  }
  var date = DateTime(now.year, now.month, now.day);
  var hasDate = false;
  if (t.contains('tomorrow')) {
    date = date.add(const Duration(days: 1));
    hasDate = true;
  } else {
    for (var i = 0; i < 7; i++) {
      if (t.contains(_days[i])) {
        var diff = (i + 1) - now.weekday;
        if (diff <= 0) diff += 7;
        date = date.add(Duration(days: diff));
        hasDate = true;
        break;
      }
    }
  }
  final clock = _parseClock(t);
  if (clock == null && !hasDate) return null;
  final parts = (clock ?? '09:00').split(':');
  var when = DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
  if (!hasDate && when.isBefore(now)) when = when.add(const Duration(days: 1));
  return when;
}

String _stripTimeWords(String t) => t
    .replaceAll(RegExp(r'\bin\s+(\d+|one|two|three|four|five|ten|fifteen|twenty|thirty|an|a|half an)\s*(minutes?|mins?|hours?|hrs?|days?)\b'), '')
    .replaceAll(RegExp(r'\b(at\s+)?\d{1,2}(:\d{2})?\s*(am|pm|a m|p m)?\b'), '')
    .replaceAll(RegExp(r'\b(tomorrow|today|tonight|this evening|this morning|on|next|at|noon|morning|evening|afternoon)\b'), '')
    .replaceAll(RegExp('\\b(${_days.join('|')})\\b'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _fmtDateTime(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${d.day} ${months[d.month - 1]}, $h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
}
