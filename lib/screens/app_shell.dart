import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/workspace_store.dart';

const accent = Color(0xFF7665D8);
String txt(dynamic value) => value?.toString() ?? '';
DateTime? dateOf(dynamic value) => value is String ? DateTime.tryParse(value) : null;
const projects = ['LeakTrace + ECDAT', 'CROSSWITNESS', 'Network Attack Forecasting', 'Bluetooth Music Middleware'];

String projectInfo(String p) {
  switch (p) {
    case 'LeakTrace + ECDAT': return 'Cryptographic inventory, leak attribution, evidence durability and renewal.';
    case 'CROSSWITNESS': return 'Digital forensics proposal, methodology, architecture and validation.';
    case 'Network Attack Forecasting': return 'Attack campaigns, datasets, baseline experiments and evaluation.';
    default: return 'Bluetooth audio middleware, synchronization and performance optimization.';
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store, required this.client});
  final WorkspaceStore store;
  final SupabaseClient? client;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final views = [
      HomePage(store: widget.store),
      PlannerPage(store: widget.store),
      PracticePage(store: widget.store),
      ReminderPage(store: widget.store),
      ResearchPage(store: widget.store),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.track_changes, color: accent, size: 28),
          SizedBox(width: 9),
          Text('CyberTrack 12', style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        actions: [
          AnimatedBuilder(
            animation: widget.store,
            builder: (context, _) => IconButton(
              onPressed: accountSheet,
              tooltip: 'Account and sync',
              icon: Icon(widget.store.syncing ? Icons.sync :
                (widget.store.cloudConfigured && widget.store.syncError == null
                  ? Icons.cloud_done : Icons.cloud_off), color: accent),
            ),
          ),
        ],
      ),
      body: SafeArea(child: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) => IndexedStack(index: tab, children: views),
      )),
      floatingActionButton: tab == 2 || tab == 3 ? FloatingActionButton.extended(
        onPressed: () => tab == 2
          ? addActivity(context, widget.store)
          : addReminder(context, widget.store),
        icon: const Icon(Icons.add),
        label: Text(tab == 2 ? 'Log practice' : 'New reminder'),
      ) : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), label: 'Planner'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), label: 'Practice'),
          NavigationDestination(icon: Icon(Icons.notifications_active_outlined), label: 'Reminders'),
          NavigationDestination(icon: Icon(Icons.science_outlined), label: 'Research'),
        ],
      ),
    );
  }

  Future<void> accountSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedBuilder(
          animation: widget.store,
          builder: (context, _) {
            final email = widget.client?.auth.currentUser?.email ?? 'Local-only mode';
            final status = !widget.store.cloudConfigured
              ? 'Cloud sync is not configured; data stays on this device.'
              : widget.store.syncError != null
                ? 'Sync issue: ' + widget.store.syncError!
                : widget.store.syncing ? 'Syncing…'
                : widget.store.lastSyncedAt == null ? 'Cloud sync is ready.'
                : 'Last synced: ' + widget.store.lastSyncedAt.toString();
            return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Account and sync', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(email),
              const SizedBox(height: 12),
              InfoPanel(status),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                onPressed: widget.store.cloudConfigured ? () async {
                  await widget.store.syncNow();
                  if (ctx.mounted) Navigator.pop(ctx);
                } : null,
                icon: const Icon(Icons.sync), label: const Text('Sync now'),
              )),
              if (widget.client?.auth.currentSession != null)
                TextButton.icon(
                  onPressed: () async {
                    await widget.client!.auth.signOut();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.logout), label: const Text('Sign out'),
                ),
              const Text('Sign in with the same email on all Android devices. Notifications are scheduled locally on each device.',
                style: TextStyle(fontSize: 11, color: Colors.black54)),
            ]);
          },
        ),
      )),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.store});
  final WorkspaceStore store;
  @override
  Widget build(BuildContext context) {
    final tasks = store.ofKind('task');
    final done = tasks.where((e) => e['done'] == true).length;
    final weekly = store.ofWeek(1);
    final weekDone = weekly.where((e) => e['done'] == true).length;
    final ctf = store.ofKind('log').where((e) => e['category'] == 'CTF').length;
    final coding = store.ofKind('log').where((e) => e['category'] == 'LeetCode' || e['category'] == 'Contest').length;
    final reminders = store.ofKind('reminder').where((e) => e['done'] != true).toList()
      ..sort((a,b) => (dateOf(a['dueAt']) ?? DateTime(2100)).compareTo(dateOf(b['dueAt']) ?? DateTime(2100)));

    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF302A55), Color(0xFF7665D8)]),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('YOUR LEARNING & RESEARCH WORKSPACE', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 10),
          const Text('Make steady progress.', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)),
          const Text('CTF · LeetCode · Reminders · Research', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Week 1 of 12', style: TextStyle(color: Colors.white)),
            Text(weekly.isEmpty ? '0%' : (weekDone * 100 ~/ weekly.length).toString() + '%', style: const TextStyle(color: Colors.white)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(
            value: weekly.isEmpty ? 0 : weekDone / weekly.length, minHeight: 8,
            backgroundColor: Colors.white24, color: Colors.white)),
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: MetricBox('Tasks done', done.toString() + '/' + tasks.length.toString(), Icons.task_alt, Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: MetricBox('CTF logs', ctf.toString(), Icons.flag, Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: MetricBox('Coding logs', coding.toString(), Icons.code, accent)),
      ]),
      const SizedBox(height: 20),
      const SectionLabel('Research workstreams', '4 active projects'),
      ...projects.map((p) {
        final list = tasks.where((e) => e['category'] == 'Research' && e['project'] == p).toList();
        return ProjectCard(name: p, done: list.where((e) => e['done'] == true).length, total: list.length);
      }),
      const SizedBox(height: 12),
      SectionLabel('Upcoming reminders', reminders.length.toString() + ' active'),
      if (reminders.isEmpty) const EmptyPanel('Add CTF registrations, research deadlines or study reminders.')
      else ...reminders.take(3).map((e) => ReminderCard(item: e,
        onToggle: () => store.update(e, {'done': true}), onDelete: () => store.remove(e))),
    ]);
  }
}

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key, required this.store});
  final WorkspaceStore store;
  @override
  State<PlannerPage> createState() => _PlannerPageState();
}
class _PlannerPageState extends State<PlannerPage> {
  int week = 1;
  @override
  Widget build(BuildContext context) {
    final tasks = widget.store.ofWeek(week);
    final done = tasks.where((e) => e['done'] == true).length;
    final groups = <String, List<Map<String,dynamic>>>{};
    for (final item in tasks) {
      groups.putIfAbsent(txt(item['category']), () => []).add(item);
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      const PageHeading('12-week planner', 'Your weekly CTF, LeetCode and research checklist.'),
      DropdownButtonFormField<int>(
        value: week,
        decoration: const InputDecoration(labelText: 'Select roadmap week'),
        items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('Week ' + (i + 1).toString()))),
        onChanged: (v) => setState(() => week = v ?? 1),
      ),
      const SizedBox(height: 12),
      ProgressPanel('Week ' + week.toString(), done, tasks.length),
      ...groups.entries.map((group) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(2,16,2,8), child: Text(group.key, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
        ...group.value.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: CheckboxListTile(
            value: item['done'] == true, activeColor: accent,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(txt(item['title']), style: TextStyle(fontWeight: FontWeight.w600, decoration: item['done'] == true ? TextDecoration.lineThrough : null)),
            subtitle: Text(txt(item['detail']), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            onChanged: (v) => widget.store.update(item, {'done': v ?? false}),
          ),
        )),
      ])),
    ]);
  }
}

class PracticePage extends StatelessWidget {
  const PracticePage({super.key, required this.store});
  final WorkspaceStore store;
  @override
  Widget build(BuildContext context) {
    final logs = store.ofKind('log')..sort((a,b) => txt(b['updatedAt']).compareTo(txt(a['updatedAt'])));
    final ctf = logs.where((e) => e['category'] == 'CTF').length;
    final coding = logs.where((e) => e['category'] == 'LeetCode' || e['category'] == 'Contest').length;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const PageHeading('Practice log', 'Record CTF challenges, writeups, LeetCode problems and coding contests.'),
      Row(children: [
        Expanded(child: MetricBox('CTF entries', ctf.toString(), Icons.flag, Colors.green)),
        const SizedBox(width: 10),
        Expanded(child: MetricBox('Coding entries', coding.toString(), Icons.code, Colors.blue)),
      ]),
      const SizedBox(height: 13),
      FilledButton.icon(onPressed: () => addActivity(context, store), icon: const Icon(Icons.add), label: const Text('Add practice entry')),
      const SizedBox(height: 17),
      const SectionLabel('Activity history', 'Latest first'),
      if (logs.isEmpty) const EmptyPanel('Your CTF challenges and coding practice will appear here.')
      else ...logs.map((e) => ActivityCard(item: e, onDelete: () => store.remove(e))),
    ]);
  }
}

class ReminderPage extends StatelessWidget {
  const ReminderPage({super.key, required this.store});
  final WorkspaceStore store;
  @override
  Widget build(BuildContext context) {
    final reminders = store.ofKind('reminder')..sort((a,b) =>
      (dateOf(a['dueAt']) ?? DateTime(2100)).compareTo(dateOf(b['dueAt']) ?? DateTime(2100)));
    final active = reminders.where((e) => e['done'] != true).toList();
    final done = reminders.where((e) => e['done'] == true).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      const PageHeading('Reminders', 'Create study reminders and deadlines. Notifications are scheduled on this device.'),
      const InfoPanel('Reminder records sync to your account. Each Android device schedules its own notification when it receives the reminder.'),
      const SizedBox(height: 13),
      FilledButton.icon(onPressed: () => addReminder(context, store), icon: const Icon(Icons.add_alarm), label: const Text('Create reminder')),
      const SizedBox(height: 17),
      SectionLabel('Upcoming', active.length.toString() + ' active'),
      if (active.isEmpty) const EmptyPanel('No active reminders. Add a deadline or task.')
      else ...active.map((e) => ReminderCard(item: e, onToggle: () => store.update(e, {'done': true}), onDelete: () => store.remove(e))),
      if (done.isNotEmpty) ...[
        const SizedBox(height: 12),
        SectionLabel('Completed', done.length.toString() + ' done'),
        ...done.map((e) => ReminderCard(item: e, onToggle: () => store.update(e, {'done': false}), onDelete: () => store.remove(e))),
      ],
    ]);
  }
}

class ResearchPage extends StatelessWidget {
  const ResearchPage({super.key, required this.store});
  final WorkspaceStore store;
  @override
  Widget build(BuildContext context) {
    final tasks = store.ofKind('task').where((e) => e['category'] == 'Research').toList();
    final logs = store.ofKind('log').where((e) => e['category'] == 'Research').toList()
      ..sort((a,b) => txt(b['updatedAt']).compareTo(txt(a['updatedAt'])));
    return ListView(padding: const EdgeInsets.all(16), children: [
      const PageHeading('Research workspace', 'Manage four parallel workstreams with weekly deliverables and notes.'),
      ...projects.map((p) {
        final list = tasks.where((e) => e['project'] == p).toList();
        final count = logs.where((e) => e['project'] == p).length;
        return Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 5),
            Text(projectInfo(p), style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
            const SizedBox(height: 10),
            ProgressPanel('Weekly milestones', list.where((e) => e['done'] == true).length, list.length),
            const SizedBox(height: 5),
            Text(count.toString() + ' research updates logged', style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
            OutlinedButton.icon(
              onPressed: () => addActivity(context, store, category: 'Research', project: p),
              icon: const Icon(Icons.note_add_outlined), label: const Text('Add research update')),
          ]),
        ));
      }),
      const SizedBox(height: 10),
      const SectionLabel('Recent research notes', 'Latest first'),
      if (logs.isEmpty) const EmptyPanel('Log a research session to keep a record of progress.')
      else ...logs.take(12).map((e) => ActivityCard(item: e, onDelete: () => store.remove(e))),
    ]);
  }
}

Future<void> addActivity(BuildContext context, WorkspaceStore store, {String category = 'CTF', String? project}) async {
  final title = TextEditingController();
  final note = TextEditingController();
  var selected = category;
  final saved = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
    builder: (ctx, setDialog) => AlertDialog(
      title: const Text('Log an activity'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (project == null) DropdownButtonFormField<String>(
          value: selected,
          decoration: const InputDecoration(labelText: 'Category'),
          items: const ['CTF', 'LeetCode', 'Contest', 'Research'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setDialog(() => selected = v ?? selected),
        ) else Align(alignment: Alignment.centerLeft, child: Text(project, style: const TextStyle(fontWeight: FontWeight.w700))),
        const SizedBox(height: 10),
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Challenge, problem or milestone')),
        const SizedBox(height: 10),
        TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes, result or next step')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, title.text.trim().isNotEmpty), child: const Text('Save')),
      ],
    ),
  ));
  if (saved == true) {
    await store.upsert({
      'id': newWorkspaceId(), 'kind': 'log',
      'category': project == null ? selected : 'Research',
      'project': project, 'title': title.text.trim(), 'note': note.text.trim(),
      'loggedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }
  title.dispose(); note.dispose();
}

Future<void> addReminder(BuildContext context, WorkspaceStore store) async {
  final title = TextEditingController();
  final notes = TextEditingController();
  var due = DateTime.now().add(const Duration(hours: 1));
  final saved = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
    builder: (ctx, setDialog) => AlertDialog(
      title: const Text('Create reminder'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Reminder title')),
        const SizedBox(height: 10),
        TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Details (optional)')),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(context: ctx, initialDate: due,
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 730)));
            if (picked != null) setDialog(() => due = DateTime(picked.year, picked.month, picked.day, due.hour, due.minute));
          },
          icon: const Icon(Icons.calendar_today),
          label: Text(due.day.toString().padLeft(2,'0') + '/' + due.month.toString().padLeft(2,'0') + '/' + due.year.toString()),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(due));
            if (picked != null) setDialog(() => due = DateTime(due.year, due.month, due.day, picked.hour, picked.minute));
          },
          icon: const Icon(Icons.schedule),
          label: Text('Time: ' + TimeOfDay.fromDateTime(due).format(context)),
        ),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, title.text.trim().isNotEmpty), child: const Text('Save')),
      ],
    ),
  ));
  if (saved == true) {
    await store.upsert({
      'id': newWorkspaceId(), 'kind': 'reminder', 'title': title.text.trim(),
      'notes': notes.text.trim(), 'dueAt': due.toUtc().toIso8601String(),
      'done': false, 'notificationId': DateTime.now().microsecondsSinceEpoch % 2000000000,
    });
  }
  title.dispose(); notes.dispose();
}

class MetricBox extends StatelessWidget {
  const MetricBox(this.label, this.value, this.icon, this.color, {super.key});
  final String label, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20), const SizedBox(height: 7),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
    ]),
  );
}
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      Flexible(child: Text(subtitle, textAlign: TextAlign.end, style: TextStyle(color: Colors.grey.shade600, fontSize: 10))),
    ]),
  );
}
class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF24213A))),
      const SizedBox(height: 5),
      Text(subtitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, height: 1.4)),
    ]),
  );
}
class ProgressPanel extends StatelessWidget {
  const ProgressPanel(this.title, this.done, this.total, {super.key});
  final String title;
  final int done, total;
  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8F7FB), borderRadius: BorderRadius.circular(13)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(done.toString() + '/' + total.toString(), style: const TextStyle(color: accent, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: fraction, minHeight: 7, backgroundColor: const Color(0xFFEAE7F4), color: accent)),
      ]),
    );
  }
}
class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.name, required this.done, required this.total});
  final String name;
  final int done, total;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(projectInfo(name), style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
      const SizedBox(height: 9),
      ProgressPanel('Weekly milestones', done, total),
    ]),
  );
}
class ReminderCard extends StatelessWidget {
  const ReminderCard({super.key, required this.item, required this.onToggle, required this.onDelete});
  final Map<String,dynamic> item;
  final VoidCallback onToggle, onDelete;
  @override
  Widget build(BuildContext context) {
    final due = dateOf(item['dueAt'])?.toLocal();
    final stamp = due == null ? 'No due date' :
      due.day.toString().padLeft(2,'0') + '/' + due.month.toString().padLeft(2,'0') + '/' +
      due.year.toString() + ' · ' + TimeOfDay.fromDateTime(due).format(context);
    final done = item['done'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        IconButton(onPressed: onToggle, icon: Icon(done ? Icons.check_circle : Icons.circle_outlined, color: done ? Colors.green : accent)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(txt(item['title']), style: TextStyle(fontWeight: FontWeight.w700, decoration: done ? TextDecoration.lineThrough : null)),
          Text(stamp, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
          if (txt(item['notes']).isNotEmpty) Text(txt(item['notes']), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
        ])),
        IconButton(onPressed: onDelete, icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey.shade500)),
      ]),
    );
  }
}
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.item, required this.onDelete});
  final Map<String,dynamic> item;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final kind = txt(item['category']);
    final icon = kind == 'CTF' ? Icons.flag : kind == 'Research' ? Icons.science : kind == 'Contest' ? Icons.emoji_events : Icons.code;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: const Color(0xFFEDEAF9), child: Icon(icon, color: accent, size: 19)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(txt(item['title']), style: const TextStyle(fontWeight: FontWeight.w700)),
          Text([kind, if (txt(item['project']).isNotEmpty) txt(item['project'])].join(' · '), style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
          if (txt(item['note']).isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(txt(item['note']), style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
          ],
        ])),
        IconButton(onPressed: onDelete, icon: Icon(Icons.close, size: 18, color: Colors.grey.shade500)),
      ]),
    );
  }
}
class InfoPanel extends StatelessWidget {
  const InfoPanel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: const Color(0xFFEFEAFB), borderRadius: BorderRadius.circular(14)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.info_outline, color: accent, size: 18),
      const SizedBox(width: 9),
      Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF4C426F), fontSize: 11, height: 1.4))),
    ]),
  );
}
class EmptyPanel extends StatelessWidget {
  const EmptyPanel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
    child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
  );
}
