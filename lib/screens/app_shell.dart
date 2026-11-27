import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'learning_planner_pages.dart';
import '../data/lessons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/crash_log.dart';
import '../services/news_service.dart';
import '../services/accounts_service.dart';
import 'accounts_page.dart';
import 'home_extras.dart';
import '../theme.dart';
import '../widgets/voice_sheet.dart';

import '../data/workspace_store.dart';

const accent = Color(0xFF4F46E5);
const appBuild = String.fromEnvironment('APP_BUILD', defaultValue: 'dev');
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
  const AppShell({super.key, required this.store, required this.client, required this.onSignedOut, required this.onReload});
  final WorkspaceStore store;
  final SupabaseClient? client;
  final VoidCallback onSignedOut;
  final VoidCallback onReload;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;

  @override
  void initState() {
    super.initState();
    Future(() async {
      await AccountsService.migrateLegacy(widget.store);
      await AccountsService.refreshStale(widget.store);
    });
  }

  static const titles = ['CyberTrack', 'Study', 'Plan', 'Track'];

  @override
  Widget build(BuildContext context) {
    final views = [
      HomePage(store: widget.store, onOpenTab: (i) => setState(() => tab = i)),
      StudyPage(store: widget.store),
      _TabbedSection(tabs: const ['Timetable', 'Reminders'], children: [
        CustomTimetablePage(store: widget.store),
        ReminderPage(store: widget.store),
      ]),
      _TabbedSection(tabs: const ['Practice log', 'Research', 'Accounts'], children: [
        PracticePage(store: widget.store),
        ResearchPage(store: widget.store),
        AccountsPage(store: widget.store),
      ]),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[tab]),
        actions: [
          AnimatedBuilder(
            animation: widget.store,
            builder: (context, _) {
              final signedIn = widget.client?.auth.currentSession != null;
              final email = widget.client?.auth.currentUser?.email ?? '';
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: accountSheet,
                  tooltip: 'Account and sync',
                  icon: CircleAvatar(
                    radius: 17,
                    backgroundColor: signedIn ? accent : const Color(0xFFE3E6F0),
                    child: signedIn && email.isNotEmpty
                        ? Text(email[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))
                        : const Icon(Icons.person_outline, size: 20, color: Color(0xFF6B7085)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) => IndexedStack(index: tab, children: views),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Voice assistant',
        onPressed: () => openVoiceAssistant(context, widget.store, (i) => setState(() => tab = i)),
        child: const Icon(Icons.mic),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Study'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Plan'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Track'),
        ],
      ),
    );
  }

  Future<void> accountSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: AnimatedBuilder(
          animation: widget.store,
          builder: (context, _) {
            final email = widget.client?.auth.currentUser?.email ?? 'Local-only mode';
            final status = !widget.store.cloudConfigured
              ? 'Your data is saved on this phone.'
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
              if (widget.client != null && widget.client?.auth.currentSession == null)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onSignedOut();
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in'),
                ),
              if (widget.client?.auth.currentSession != null)
                TextButton.icon(
                  onPressed: () async {
                    await widget.client!.auth.signOut();
                    if (ctx.mounted) Navigator.pop(ctx);
                    widget.onSignedOut();
                  },
                  icon: const Icon(Icons.logout), label: const Text('Sign out'),
                ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link),
                title: const Text('Linked accounts'),
                subtitle: const Text('LeetCode, TryHackMe, HTB, picoCTF, CTFtime, Codeforces, GitHub'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountsPage(store: widget.store, standalone: true)));
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Report a problem'),
                subtitle: Text(CrashLog.entries().isEmpty
                    ? 'Opens a GitHub issue form'
                    : '${CrashLog.entries().length} recent error(s) will be attached'),
                onTap: () => launchUrl(CrashLog.reportUrl(version: appBuild), mode: LaunchMode.externalApplication),
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
  const HomePage({super.key, required this.store, required this.onOpenTab});
  final WorkspaceStore store;
  final void Function(int) onOpenTab;
  @override
  Widget build(BuildContext context) {
    final scheduleCount = store.ofKind('schedule').length;
    final researchLogs = store.ofKind('log').where((e) => e['category'] == 'Research').toList();
    final ctf = store.ofKind('log').where((e) => e['category'] == 'CTF').length;
    final coding = store.ofKind('log').where((e) => e['category'] == 'LeetCode' || e['category'] == 'Contest').length;
    final reminders = store.ofKind('reminder').where((e) => e['done'] != true).toList()
      ..sort((a,b) => (dateOf(a['dueAt']) ?? DateTime(2100)).compareTo(dateOf(b['dueAt']) ?? DateTime(2100)));

    final solvedIds = store.ofKind('lesson').where((e) => e['done'] == true).map((e) => e['id']).toSet();
    final nextLesson = lessons.where((l) => !solvedIds.contains(l.id)).firstOrNull;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)]),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('YOUR LEARNING & RESEARCH WORKSPACE', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 10),
          Text(greeting + '.', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)),
          const Text('Custom timetable · CTF · DSA · Research', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Personal study sessions', style: TextStyle(color: Colors.white)),
            Text(scheduleCount.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      if (solvedIds.isEmpty && scheduleCount == 0) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Welcome! Start in 3 easy steps',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              for (final step in const [
                '1.  Open Study and try your first topic. Hints are there if you get stuck.',
                '2.  Add a few study sessions to Timetable that fit your day.',
                '3.  Log what you practice so you can see your progress grow.',
              ])
                Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(step, style: const TextStyle(height: 1.4))),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: FilledButton(onPressed: () => onOpenTab(1), child: const Text('Start learning'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: () => onOpenTab(2), child: const Text('Plan my week'))),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 14),
      ],
      DailyGoalCard(store: store),
      const SizedBox(height: 14),
      DueReviewCard(store: store),
      DeadlinesCard(store: store, onOpenResearch: () => onOpenTab(3)),
      Card(
        child: ListTile(
          onTap: () => onOpenTab(1),
          leading: const CircleAvatar(
              backgroundColor: Color(0xFFEEF0FF),
              child: Icon(Icons.menu_book_outlined, color: accent)),
          title: Text(nextLesson == null ? 'All study topics solved' : 'Continue learning',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(nextLesson == null
              ? 'Great work. Revisit notes any time.'
              : nextLesson.area + ' · ' + nextLesson.title),
          trailing: Text(solvedIds.length.toString() + '/' + lessons.length.toString(),
              style: const TextStyle(fontWeight: FontWeight.w800, color: accent)),
        ),
      ),
      const SizedBox(height: 14),
      TodayCard(store: store),
      const SizedBox(height: 14),
      const NewsSection(),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: MetricBox('Research notes', researchLogs.length.toString(), Icons.science_outlined, Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: MetricBox('CTF logs', ctf.toString(), Icons.flag, Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: MetricBox('Coding logs', coding.toString(), Icons.code, accent)),
      ]),
      const SizedBox(height: 20),
      const SectionLabel('Research workstreams', '4 active projects'),
      ...projects.map((p) => ProjectCard(
        name: p,
        updates: researchLogs.where((e) => e['project'] == p).length,
      )),
      const SizedBox(height: 12),
      SectionLabel('Upcoming reminders', reminders.length.toString() + ' active'),
      if (reminders.isEmpty) const EmptyPanel('Add CTF registrations, research deadlines or study reminders.')
      else ...reminders.take(3).map((e) => ReminderCard(item: e,
        onToggle: () => store.update(e, {'done': true, 'doneAt': DateTime.now().toUtc().toIso8601String()}), onDelete: () => store.remove(e))),
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
      LinkedAccountsSummary(
        store: store,
        onManage: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountsPage(store: store, standalone: true))),
      ),
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
      else ...active.map((e) => ReminderCard(item: e, onToggle: () => store.update(e, {'done': true, 'doneAt': DateTime.now().toUtc().toIso8601String()}), onDelete: () => store.remove(e))),
      if (done.isNotEmpty) ...[
        const SizedBox(height: 12),
        SectionLabel('Completed', done.length.toString() + ' done'),
        ...done.map((e) => ReminderCard(item: e, onToggle: () => store.update(e, {'done': false, 'doneAt': null}), onDelete: () => store.remove(e))),
      ],
    ]);
  }
}

class ResearchPage extends StatelessWidget {
  const ResearchPage({super.key, required this.store});
  final WorkspaceStore store;
  @override
  Widget build(BuildContext context) {
    final logs = store.ofKind('log').where((e) => e['category'] == 'Research').toList()
      ..sort((a,b) => txt(b['updatedAt']).compareTo(txt(a['updatedAt'])));
    return ListView(padding: const EdgeInsets.all(16), children: [
      const PageHeading('Research workspace', 'Manage four parallel workstreams and record your research notes.'),
      ...projects.map((p) {
        final count = logs.where((e) => e['project'] == p).length;
        final ms = upcomingMilestones(store, project: p);
        final doneMs = store.ofKind('milestone').where((m) => m['project'] == p && m['done'] == true).length;
        return Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 5),
            Text(projectInfo(p), style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 8),
            Text('$count updates · ${ms.length} open milestone${ms.length == 1 ? '' : 's'}${doneMs > 0 ? ' · $doneMs done' : ''}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12, fontFeatures: [FontFeature.tabularFigures()])),
            for (final m in ms.take(4)) MilestoneTile(item: m, store: store),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                onPressed: () => addActivity(context, store, category: 'Research', project: p),
                icon: const Icon(Icons.note_add_outlined), label: const Text('Add update')),
              OutlinedButton.icon(
                onPressed: () => addMilestone(context, store, p),
                icon: const Icon(Icons.flag_outlined), label: const Text('Add milestone')),
            ]),
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
      Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1F2340))),
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
      decoration: BoxDecoration(color: const Color(0xFFF7F8FC), borderRadius: BorderRadius.circular(13)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(done.toString() + '/' + total.toString(), style: const TextStyle(color: accent, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: fraction, minHeight: 7, backgroundColor: const Color(0xFFE4E7F5), color: accent)),
      ]),
    );
  }
}
class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.name, required this.updates});
  final String name;
  final int updates;
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
      Text(updates == 0 ? 'No research updates yet' : '$updates research updates logged',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
        CircleAvatar(backgroundColor: const Color(0xFFEEF0FF), child: Icon(icon, color: accent, size: 19)),
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
    decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(14)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.info_outline, color: accent, size: 18),
      const SizedBox(width: 9),
      Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF3730A3), fontSize: 11, height: 1.4))),
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


class _TabbedSection extends StatelessWidget {
  const _TabbedSection({required this.tabs, required this.children});
  final List<String> tabs;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: tabs.length,
        child: Column(children: [
          TabBar(tabs: [for (final t in tabs) Tab(text: t)]),
          Expanded(child: TabBarView(children: children)),
        ]),
      );
}


// ─────────────────────────── Done today ───────────────────────────

class TodayCard extends StatelessWidget {
  const TodayCard({super.key, required this.store});
  final WorkspaceStore store;

  bool _today(dynamic iso) {
    final d = DateTime.tryParse(iso?.toString() ?? '')?.toLocal();
    final n = DateTime.now();
    return d != null && d.year == n.year && d.month == n.month && d.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    final entries = <(IconData, Color, String, String)>[];
    for (final e in store.ofKind('lesson')) {
      if (e['done'] == true && _today(e['doneAt'])) {
        entries.add((Icons.school, AppColors.success, 'Solved', txt(e['title'])));
      }
    }
    for (final e in store.ofKind('reminder')) {
      if (e['done'] == true && _today(e['doneAt'])) {
        entries.add((Icons.task_alt, AppColors.accent, 'Completed', txt(e['title'])));
      }
    }
    for (final e in store.ofKind('log')) {
      if (_today(e['loggedAt'] ?? e['updatedAt'])) {
        entries.add((Icons.edit_note, AppColors.primary, txt(e['category']).isEmpty ? 'Log' : txt(e['category']), txt(e['title'])));
      }
    }
    final todayName = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][DateTime.now().weekday - 1];
    final sessions = store.ofKind('schedule').where((e) => e['day'] == todayName).toList()
      ..sort((a, b) => txt(a['startTime']).compareTo(txt(b['startTime'])));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.today, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Today', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('${entries.length} done', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.success)),
          ]),
          if (sessions.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final s in sessions.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  const Icon(Icons.schedule, size: 16, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Text(txt(s['startTime']), style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(txt(s['title']), overflow: TextOverflow.ellipsis)),
                ]),
              ),
          ],
          const SizedBox(height: 10),
          if (entries.isEmpty)
            const Text('Nothing logged yet. Tap the mic and say what you did, e.g. "I solved two sum".',
                style: TextStyle(color: AppColors.muted, height: 1.4))
          else
            for (final e in entries.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Icon(e.$1, size: 18, color: e.$2),
                  const SizedBox(width: 8),
                  Text('${e.$3}: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Expanded(child: Text(e.$4, overflow: TextOverflow.ellipsis)),
                ]),
              ),
        ]),
      ),
    );
  }
}

// ─────────────────────────── Daily tech news ───────────────────────────

class NewsSection extends StatefulWidget {
  const NewsSection({super.key});
  @override
  State<NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  late Future<List<NewsItem>> future = NewsService.load();

  void refresh() => setState(() => future = NewsService.load(refresh: true));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NewsItem>>(
      future: future,
      builder: (context, snap) {
        final items = snap.data ?? const <NewsItem>[];
        final cyber = items.where((i) => i.cyber).toList();
        final tech = items.where((i) => !i.cyber).toList();
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.newspaper, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(child: Text("Today's tech news", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                IconButton(tooltip: 'Refresh', onPressed: refresh, icon: const Icon(Icons.refresh, color: AppColors.muted)),
              ]),
              if (snap.connectionState != ConnectionState.done)
                const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
              else if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 4, 8, 8),
                  child: Text('Couldn\'t load news. Check your internet and tap refresh.', style: TextStyle(color: AppColors.muted)),
                )
              else ...[
                _NewsGroup(label: 'Cybersecurity', color: AppColors.danger, items: cyber.take(3).toList()),
                _NewsGroup(label: 'Tech', color: AppColors.primary, items: tech.take(3).toList()),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NewsPage(items: items))),
                    child: Text('See all ${items.length} stories'),
                  ),
                ),
              ],
            ]),
          ),
        );
      },
    );
  }
}

class _NewsGroup extends StatelessWidget {
  const _NewsGroup({required this.label, required this.color, required this.items});
  final String label;
  final Color color;
  final List<NewsItem> items;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 2),
        child: Text(label.toUpperCase(), style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w800, color: color)),
      ),
      for (final n in items) NewsTile(item: n),
    ]);
  }
}

class NewsTile extends StatelessWidget {
  const NewsTile({super.key, required this.item});
  final NewsItem item;
  @override
  Widget build(BuildContext context) {
    final age = DateTime.now().toUtc().difference(item.published);
    final ago = age.inMinutes < 60 ? '${age.inMinutes}m ago' : (age.inHours < 24 ? '${age.inHours}h ago' : '${age.inDays}d ago');
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => launchUrl(Uri.parse(item.url), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35)),
          const SizedBox(height: 3),
          Text('${item.source} · $ago', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
      ),
    );
  }
}

class NewsPage extends StatelessWidget {
  const NewsPage({super.key, required this.items});
  final List<NewsItem> items;
  @override
  Widget build(BuildContext context) {
    final cyber = items.where((i) => i.cyber).toList();
    final tech = items.where((i) => !i.cyber).toList();
    return Scaffold(
      appBar: AppBar(title: const Text("Today's tech news")),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        Text('${items.length} stories · ${cyber.length} cybersecurity, ${tech.length} tech', style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 8),
        _NewsGroup(label: 'Cybersecurity', color: AppColors.danger, items: cyber),
        const Divider(height: 24),
        _NewsGroup(label: 'Tech', color: AppColors.primary, items: tech),
      ]),
    );
  }
}
