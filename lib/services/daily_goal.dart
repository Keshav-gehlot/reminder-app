import 'package:shared_preferences/shared_preferences.dart';

import '../data/workspace_store.dart';

class DailyGoal {
  const DailyGoal({required this.topics, required this.problems, required this.nudgeHour});
  final int topics; // topics solved or reviewed per day
  final int problems; // practice log entries per day
  final int nudgeHour; // evening reminder hour (24h)

  static const _kTopics = 'cybertrack_goal_topics';
  static const _kProblems = 'cybertrack_goal_problems';
  static const _kHour = 'cybertrack_goal_hour';

  static Future<DailyGoal> load() async {
    final p = await SharedPreferences.getInstance();
    return DailyGoal(
      topics: p.getInt(_kTopics) ?? 1,
      problems: p.getInt(_kProblems) ?? 2,
      nudgeHour: p.getInt(_kHour) ?? 20,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kTopics, topics);
    await p.setInt(_kProblems, problems);
    await p.setInt(_kHour, nudgeHour);
  }
}

class GoalProgress {
  const GoalProgress(this.topics, this.problems);
  final int topics, problems;
  bool met(DailyGoal g) => topics >= g.topics && problems >= g.problems;
}

bool _isToday(dynamic value, DateTime now) {
  final d = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  return d != null && d.year == now.year && d.month == now.month && d.day == now.day;
}

GoalProgress todayProgress(WorkspaceStore store, {DateTime? now}) {
  final n = now ?? DateTime.now();
  var topics = 0;
  for (final e in store.ofKind('lesson')) {
    if ((e['done'] == true && _isToday(e['doneAt'], n)) || _isToday(e['lastReviewAt'], n)) topics++;
  }
  final problems = store.ofKind('log').where((e) => _isToday(e['loggedAt'], n)).length;
  return GoalProgress(topics, problems);
}
