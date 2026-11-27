import 'package:flutter/material.dart';

import '../data/workspace_store.dart';
import '../services/daily_goal.dart';
import '../services/leetcode_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import 'learning_planner_pages.dart';

const _tabular = [FontFeature.tabularFigures()];

String _shortDate(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month - 1]}';
}

// ─────────────────────────────── Daily goal ───────────────────────────────

class DailyGoalCard extends StatefulWidget {
  const DailyGoalCard({super.key, required this.store});
  final WorkspaceStore store;
  @override
  State<DailyGoalCard> createState() => _DailyGoalCardState();
}

class _DailyGoalCardState extends State<DailyGoalCard> {
  DailyGoal? goal;
  bool? lastMet;

  @override
  void initState() {
    super.initState();
    DailyGoal.load().then((g) {
      if (mounted) setState(() => goal = g);
    });
  }

  void _syncNudge(DailyGoal g, GoalProgress p) {
    final met = p.met(g);
    if (lastMet == met) return;
    lastMet = met;
    final streak = studyStreak(widget.store);
    final body = met
        ? 'Goal done today. Come back tomorrow to keep your ${streak > 0 ? '$streak-day ' : ''}streak.'
        : 'Still to do today: ${(g.topics - p.topics).clamp(0, 99)} topic(s), ${(g.problems - p.problems).clamp(0, 99)} practice entr${g.problems - p.problems == 1 ? 'y' : 'ies'}.';
    NotificationService.instance.scheduleNudge(hour: g.nudgeHour, metToday: met, body: body);
  }

  Future<void> edit() async {
    final g = goal;
    if (g == null) return;
    var topics = g.topics, problems = g.problems, hour = g.nudgeHour;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Daily goal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _Stepper(label: 'Topics solved or reviewed', value: topics, min: 0, max: 10, onChanged: (v) => set(() => topics = v)),
              _Stepper(label: 'Practice log entries', value: problems, min: 0, max: 20, onChanged: (v) => set(() => problems = v)),
              _Stepper(
                label: 'Evening reminder',
                value: hour,
                min: 16,
                max: 23,
                format: (v) => '${v > 12 ? v - 12 : v} pm',
                onChanged: (v) => set(() => hour = v),
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save goal'))),
            ]),
          ),
        ),
      ),
    );
    if (ok != true) return;
    final next = DailyGoal(topics: topics, problems: problems, nudgeHour: hour);
    await next.save();
    lastMet = null;
    if (mounted) setState(() => goal = next);
  }

  @override
  Widget build(BuildContext context) {
    final g = goal;
    if (g == null) return const SizedBox(height: 120);
    final p = todayProgress(widget.store);
    _syncNudge(g, p);
    final met = p.met(g);
    final streak = studyStreak(widget.store);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(met ? Icons.check_circle : Icons.flag_circle_outlined, color: met ? AppColors.success : AppColors.primary),
            const SizedBox(width: 8),
            Text(met ? 'Daily goal done' : "Today's goal", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const Spacer(),
            if (streak > 0)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(children: [
                  const Icon(Icons.local_fire_department, color: AppColors.accent, size: 20),
                  Text('$streak', style: const TextStyle(fontWeight: FontWeight.w800, fontFeatures: _tabular)),
                ]),
              ),
            IconButton(onPressed: edit, tooltip: 'Edit goal', icon: const Icon(Icons.tune)),
          ]),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(children: [
              _GoalBar(label: 'Topics', done: p.topics, target: g.topics),
              const SizedBox(height: 10),
              _GoalBar(label: 'Practice', done: p.problems, target: g.problems),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _GoalBar extends StatelessWidget {
  const _GoalBar({required this.label, required this.done, required this.target});
  final String label;
  final int done, target;
  @override
  Widget build(BuildContext context) {
    final value = target == 0 ? 1.0 : (done / target).clamp(0.0, 1.0);
    final complete = done >= target;
    return Row(children: [
      SizedBox(width: 70, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 10,
            backgroundColor: AppColors.line,
            color: complete ? AppColors.success : AppColors.primary,
          ),
        ),
      ),
      SizedBox(
        width: 48,
        child: Text('$done/$target', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: _tabular)),
      ),
    ]);
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.min, required this.max, required this.onChanged, this.format});
  final String label;
  final int value, min, max;
  final ValueChanged<int> onChanged;
  final String Function(int)? format;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          IconButton(onPressed: value > min ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
          SizedBox(
            width: 52,
            child: Text(format?.call(value) ?? '$value',
                textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, fontFeatures: _tabular)),
          ),
          IconButton(onPressed: value < max ? () => onChanged(value + 1) : null, icon: const Icon(Icons.add_circle_outline)),
        ]),
      );
}

// ─────────────────────────────── Due for review ───────────────────────────────

class DueReviewCard extends StatelessWidget {
  const DueReviewCard({super.key, required this.store});
  final WorkspaceStore store;
  @override
  Widget build(BuildContext context) {
    final due = dueLessons(store);
    if (due.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        color: AppColors.warningSoft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.event_repeat, color: AppColors.warning),
              const SizedBox(width: 8),
              const Text('Due for review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${due.length}', style: const TextStyle(fontWeight: FontWeight.w800, fontFeatures: _tabular)),
            ]),
            const SizedBox(height: 4),
            const Text('A quick review now helps it stick for weeks.', style: TextStyle(color: AppColors.muted)),
            for (final l in due.take(3))
              ListTile(
                contentPadding: EdgeInsets.zero,
                minVerticalPadding: 12,
                title: Text(l.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(l.area == 'AI' ? 'AI / ML' : l.area),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openLesson(context, store, l),
              ),
            if (due.length > 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('+${due.length - 3} more in Study → Due for review', style: const TextStyle(color: AppColors.muted)),
              ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────── Research milestones ───────────────────────────────

List<Map<String, dynamic>> upcomingMilestones(WorkspaceStore store, {String? project}) {
  final list = store
      .ofKind('milestone')
      .where((m) => m['done'] != true && m['deleted'] != true && (project == null || m['project'] == project))
      .toList()
    ..sort((a, b) => (a['dueAt']?.toString() ?? '').compareTo(b['dueAt']?.toString() ?? ''));
  return list;
}

class DeadlinesCard extends StatelessWidget {
  const DeadlinesCard({super.key, required this.store, required this.onOpenResearch});
  final WorkspaceStore store;
  final VoidCallback onOpenResearch;
  @override
  Widget build(BuildContext context) {
    final list = upcomingMilestones(store);
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.flag_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Research deadlines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(onPressed: onOpenResearch, child: const Text('All')),
            ]),
            for (final m in list.take(3)) MilestoneTile(item: m, store: store, showProject: true),
          ]),
        ),
      ),
    );
  }
}

class MilestoneTile extends StatelessWidget {
  const MilestoneTile({super.key, required this.item, required this.store, this.showProject = false});
  final Map<String, dynamic> item;
  final WorkspaceStore store;
  final bool showProject;
  @override
  Widget build(BuildContext context) {
    final due = DateTime.tryParse(item['dueAt']?.toString() ?? '')?.toLocal();
    final now = DateTime.now();
    final days = due == null ? null : DateTime(due.year, due.month, due.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    final done = item['done'] == true;
    final overdue = !done && days != null && days < 0;
    final soon = !done && days != null && days >= 0 && days <= 3;
    final when = days == null
        ? ''
        : days < 0
            ? '${-days}d overdue'
            : days == 0
                ? 'Today'
                : days == 1
                    ? 'Tomorrow'
                    : 'in ${days}d · ${_shortDate(due!)}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: done,
        onChanged: (v) => store.update(item, {'done': v == true, 'doneAt': v == true ? DateTime.now().toUtc().toIso8601String() : null}),
      ),
      title: Text(item['title']?.toString() ?? '',
          style: TextStyle(fontWeight: FontWeight.w700, decoration: done ? TextDecoration.lineThrough : null)),
      subtitle: Text(
        [if (showProject) item['project']?.toString() ?? '', when].where((s) => s.isNotEmpty).join(' · '),
        style: TextStyle(color: overdue ? AppColors.danger : (soon ? AppColors.warning : AppColors.muted), fontWeight: overdue || soon ? FontWeight.w700 : null),
      ),
      trailing: IconButton(
        tooltip: 'Delete milestone',
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          await store.remove(item);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Milestone deleted'),
              action: SnackBarAction(label: 'Undo', onPressed: () => store.upsert({...item, 'deleted': false})),
            ));
          }
        },
      ),
    );
  }
}

Future<void> addMilestone(BuildContext context, WorkspaceStore store, String project) async {
  final title = TextEditingController();
  var due = DateTime.now().add(const Duration(days: 7));
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: const Text('Add milestone'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(project, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted)),
          const SizedBox(height: 10),
          TextField(
            controller: title,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Milestone', hintText: 'e.g. Submit draft to guide'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                  context: ctx, initialDate: due, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 1000)));
              if (picked != null) set(() => due = DateTime(picked.year, picked.month, picked.day, 9));
            },
            icon: const Icon(Icons.event),
            label: Text('Due ${_shortDate(due)} ${due.year}'),
          ),
          const SizedBox(height: 6),
          const Text('You get a reminder at 9 am on the due date.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, title.text.trim().isNotEmpty), child: const Text('Add')),
        ],
      ),
    ),
  );
  if (ok == true) {
    final at = DateTime(due.year, due.month, due.day, 9);
    await store.upsert({
      'id': newWorkspaceId(),
      'kind': 'milestone',
      'project': project,
      'title': title.text.trim(),
      'notes': '$project milestone due today',
      'dueAt': at.toUtc().toIso8601String(),
      'done': false,
      'notificationId': DateTime.now().microsecondsSinceEpoch % 2000000000,
    });
  }
  title.dispose();
}

// ─────────────────────────────── LeetCode import ───────────────────────────────

class LeetCodeCard extends StatefulWidget {
  const LeetCodeCard({super.key});
  @override
  State<LeetCodeCard> createState() => _LeetCodeCardState();
}

class _LeetCodeCardState extends State<LeetCodeCard> {
  LeetCodeStats? stats;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    LeetCodeService.cached().then((s) {
      if (mounted) setState(() => stats = s);
    });
  }

  Future<void> sync({bool ask = false}) async {
    var user = stats?.username ?? await LeetCodeService.username() ?? '';
    if (ask || user.isEmpty) {
      if (!mounted) return;
      final c = TextEditingController(text: user);
      final entered = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Connect LeetCode'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Enter your public LeetCode username. Only solved counts are read.'),
            const SizedBox(height: 12),
            TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'Username', prefixText: 'leetcode.com/u/')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Import')),
          ],
        ),
      );
      c.dispose();
      if (entered == null || entered.isEmpty) return;
      user = entered;
    }
    setState(() => busy = true);
    try {
      final s = await LeetCodeService.sync(user);
      if (mounted) setState(() => stats = s);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = stats;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.code, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(s == null ? 'LeetCode progress' : 'LeetCode · ${s.username}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
            ),
            if (busy)
              const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            else if (s != null) ...[
              IconButton(onPressed: () => sync(ask: true), tooltip: 'Change username', icon: const Icon(Icons.edit_outlined)),
              IconButton(onPressed: sync, tooltip: 'Refresh', icon: const Icon(Icons.refresh)),
            ],
          ]),
          if (s == null) ...[
            const Text('Import your solved counts so DSA progress lives in one place.', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: busy ? null : () => sync(ask: true), icon: const Icon(Icons.download), label: const Text('Connect LeetCode')),
          ] else ...[
            const SizedBox(height: 6),
            Row(children: [
              _Count('Total', s.total, AppColors.ink),
              _Count('Easy', s.easy, AppColors.success),
              _Count('Medium', s.medium, AppColors.warning),
              _Count('Hard', s.hard, AppColors.danger),
            ]),
            const SizedBox(height: 6),
            Text('Updated ${_shortDate(s.fetchedAt.toLocal())}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
          const SizedBox(height: 4),
          const Text('TryHackMe and picoCTF have no public API, so log those rooms with "Add practice entry".',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, fontFeatures: _tabular)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
      );
}
