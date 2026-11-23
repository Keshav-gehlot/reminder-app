import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../data/lessons.dart';
import '../data/workspace_store.dart';
import '../theme.dart';
import '../widgets/notes_view.dart';

const Color _accent = AppColors.primary;
String _str(dynamic value) => value?.toString() ?? '';

Map<String, dynamic>? _progressFor(WorkspaceStore store, Lesson lesson) {
  for (final entry in store.ofKind('lesson')) {
    if (entry['id'] == lesson.id) return entry;
  }
  return null;
}

bool _isDone(WorkspaceStore store, Lesson l) => _progressFor(store, l)?['done'] == true;

bool _needsReview(WorkspaceStore store, Lesson lesson) {
  final progress = _progressFor(store, lesson);
  return progress != null && progress['confidence'] == 'review';
}

Future<void> _saveProgress(WorkspaceStore store, Lesson lesson, Map<String, dynamic> changes) {
  final current = _progressFor(store, lesson) ?? <String, dynamic>{};
  return store.upsert({
    ...current,
    'id': lesson.id,
    'kind': 'lesson',
    'title': lesson.title,
    'area': lesson.area,
    ...changes,
  });
}

int _levelRank(String level) => level == 'Beginner' ? 0 : (level == 'Intermediate' ? 1 : 2);

int studyStreak(WorkspaceStore store) {
  final days = <DateTime>{};
  for (final e in store.ofKind('lesson')) {
    if (e['done'] == true) {
      final d = DateTime.tryParse(_str(e['doneAt']))?.toLocal();
      if (d != null) days.add(DateTime(d.year, d.month, d.day));
    }
  }
  final now = DateTime.now();
  var day = DateTime(now.year, now.month, now.day);
  if (!days.contains(day)) day = DateTime(day.year, day.month, day.day - 1);
  var count = 0;
  while (days.contains(day)) {
    count++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return count;
}

List<Lesson> _ordered(String area) => lessons.where((l) => l.area == area).toList()
  ..sort((a, b) {
    final c = _levelRank(a.level).compareTo(_levelRank(b.level));
    return c != 0 ? c : lessons.indexOf(a).compareTo(lessons.indexOf(b));
  });

// ─────────────────────────────── Study list ───────────────────────────────

class StudyPage extends StatefulWidget {
  const StudyPage({super.key, required this.store});
  final WorkspaceStore store;
  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  String area = 'DSA', filter = 'All', query = '';

  void open(Lesson l) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => LessonPage(lesson: l, store: widget.store)));

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final all = _ordered(area);
    final solved = all.where((l) => _isDone(store, l)).length;
    final upNext = all.where((l) => !_isDone(store, l)).firstOrNull;
    final q = query.trim().toLowerCase();
    final list = all.where((t) {
      if (filter == 'To review' && !_needsReview(store, t)) return false;
      if (filter != 'All' && filter != 'To review' && t.level != filter) return false;
      return q.isEmpty || t.title.toLowerCase().contains(q) || t.summary.toLowerCase().contains(q);
    }).toList();

    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
      SegmentedButton<String>(
        style: SegmentedButton.styleFrom(minimumSize: const Size(0, 46)),
        segments: const [
          ButtonSegment(value: 'DSA', label: Text('DSA'), icon: Icon(Icons.code)),
          ButtonSegment(value: 'CTF', label: Text('CTF'), icon: Icon(Icons.security)),
          ButtonSegment(value: 'AI', label: Text('AI / ML'), icon: Icon(Icons.psychology_outlined)),
        ],
        selected: {area},
        onSelectionChanged: (v) => setState(() {
          area = v.first;
          filter = 'All';
        }),
      ),
      const SizedBox(height: 14),
      if (upNext != null) _UpNextCard(lesson: upNext, solved: solved, total: all.length, onTap: () => open(upNext))
      else _AllDoneCard(total: all.length),
      const SizedBox(height: 16),
      TextField(
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search topics'),
        onChanged: (v) => setState(() => query = v),
      ),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final f in const ['All', 'Beginner', 'Intermediate', 'Advanced', 'To review'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text(f), selected: filter == f, onSelected: (_) => setState(() => filter = f)),
            ),
        ]),
      ),
      const SizedBox(height: 6),
      if (list.isEmpty)
        const Padding(
          padding: EdgeInsets.all(32),
          child: Text('Nothing matches. Try another word or filter.', textAlign: TextAlign.center),
        )
      else
        for (var i = 0; i < list.length; i++)
          _TopicRow(
            index: all.indexOf(list[i]) + 1,
            lesson: list[i],
            done: _isDone(store, list[i]),
            review: _needsReview(store, list[i]),
            isNext: identical(list[i], upNext),
            onTap: () => open(list[i]),
          ),
    ]);
  }
}

class _UpNextCard extends StatelessWidget {
  const _UpNextCard({required this.lesson, required this.solved, required this.total, required this.onTap});
  final Lesson lesson;
  final int solved, total;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('UP NEXT', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const Spacer(),
                Text('$solved / $total done', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
              ]),
              const SizedBox(height: 8),
              Text(lesson.title, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(lesson.summary, style: const TextStyle(color: Colors.white70, height: 1.4)),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : solved / total,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Row(children: [
                const Icon(Icons.play_circle_fill, color: Colors.white),
                const SizedBox(width: 8),
                Text('Start · ${lesson.minutes} min', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ]),
            ]),
          ),
        ),
      );
}

class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard({required this.total});
  final int total;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          const Icon(Icons.emoji_events, color: AppColors.success, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text('All $total topics solved. Revisit anything flagged "To review".',
                style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4)),
          ),
        ]),
      );
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.index, required this.lesson, required this.done, required this.review, required this.isNext, required this.onTap});
  final int index;
  final Lesson lesson;
  final bool done, review, isNext;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: isNext ? AppColors.primary : AppColors.line, width: isNext ? 1.5 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done ? AppColors.successSoft : AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded, color: AppColors.success)
                      : Text('$index', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(lesson.title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(lesson.summary, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.circle, size: 8, color: levelColor(lesson.level)),
                      const SizedBox(width: 5),
                      Text(lesson.level, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      const Icon(Icons.schedule, size: 13, color: AppColors.muted),
                      const SizedBox(width: 3),
                      Text('${lesson.minutes} min', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      if (lesson.practice.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.science_outlined, size: 13, color: AppColors.muted),
                        const SizedBox(width: 3),
                        Text('${lesson.practice.length} labs', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ]),
                  ]),
                ),
                if (review) const Icon(Icons.flag, color: AppColors.accent)
                else const Icon(Icons.chevron_right, color: AppColors.muted),
              ]),
            ),
          ),
        ),
      );
}

// ─────────────────────────────── Lesson page ───────────────────────────────

class LessonPage extends StatefulWidget {
  const LessonPage({super.key, required this.lesson, required this.store});
  final Lesson lesson;
  final WorkspaceStore store;
  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  late final TextEditingController answer;
  double noteSize = 16;

  @override
  void initState() {
    super.initState();
    answer = TextEditingController(text: _str(_progressFor(widget.store, widget.lesson)?['answer']));
  }

  @override
  void dispose() {
    answer.dispose();
    super.dispose();
  }

  void toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> askTutor() async {
    final t = widget.lesson;
    final attempt = answer.text.trim();
    final prompt = 'Act as a patient ${t.area == 'CTF' ? 'cybersecurity CTF' : 'DSA'} tutor. '
        'Topic: ${t.title}. Question: ${t.question}'
        '${attempt.isEmpty ? '' : ' My attempt so far: $attempt'} '
        'Give one hint at a time and do not reveal the full solution until I ask. '
        'Then explain the concept, approach, edge cases and complexity.';
    await Clipboard.setData(ClipboardData(text: prompt));
    toast('Tutor prompt copied. Paste it into ChatGPT or Claude.');
  }

  Future<void> toggleSolved(bool done) async {
    final t = widget.lesson;
    if (done) {
      await _saveProgress(widget.store, t, {'done': false, 'answer': answer.text});
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Nice work! How confident are you?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          ListTile(leading: const Icon(Icons.sentiment_very_satisfied), title: const Text('Confident, I got it'), onTap: () => Navigator.pop(ctx, 'easy')),
          ListTile(leading: const Icon(Icons.sentiment_satisfied), title: const Text('Okay, with a few hints'), onTap: () => Navigator.pop(ctx, 'ok')),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Review this again later'),
            subtitle: const Text('Adds it to your "To review" list'),
            onTap: () => Navigator.pop(ctx, 'review'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (choice == null) return;
    await _saveProgress(widget.store, t, {
      'done': true,
      'doneAt': DateTime.now().toUtc().toIso8601String(),
      'confidence': choice,
      'answer': answer.text,
    });
    if (!mounted) return;
    final next = _ordered(t.area).where((l) => !_isDone(widget.store, l)).firstOrNull;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.celebration, color: AppColors.accent, size: 36),
        title: const Text('Topic complete'),
        content: Text(next == null ? 'You have finished every ${t.area} topic.' : 'Up next: ${next.title}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Stay here')),
          if (next != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => LessonPage(lesson: next, store: widget.store)));
              },
              child: const Text('Next topic'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.lesson;
    final hasLabs = t.practice.isNotEmpty || t.exam.isNotEmpty;
    return DefaultTabController(
      length: hasLabs ? 3 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.title),
          bottom: TabBar(tabs: [
            const Tab(text: 'Learn'),
            const Tab(text: 'Practice'),
            if (hasLabs) Tab(text: t.area == 'CTF' ? 'Labs & exams' : (t.area == 'AI' ? 'Hands-on' : 'Problems')),
          ]),
        ),
        body: AnimatedBuilder(
          animation: widget.store,
          builder: (context, _) => TabBarView(children: [
            _KeepAlive(child: learnTab()),
            practiceTab(),
            if (hasLabs) labsTab(),
          ]),
        ),
      ),
    );
  }

  Widget learnTab() {
    final t = widget.lesson;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
      LessonVideo(videoId: t.videoId, title: t.videoTitle),
      const SizedBox(height: 18),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _Pill(icon: Icons.circle, iconColor: levelColor(t.level), label: t.level),
        _Pill(icon: Icons.schedule, label: '${t.minutes} min'),
        _Pill(icon: Icons.speed, label: t.complexity.split('·').first.trim()),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Key points', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          for (final k in t.keyPoints)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(k, style: const TextStyle(height: 1.4))),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 6),
      Row(children: [
        const Text('Notes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const Spacer(),
        IconButton(
          tooltip: 'Smaller text',
          onPressed: noteSize > 13 ? () => setState(() => noteSize--) : null,
          icon: const Icon(Icons.text_decrease),
        ),
        IconButton(
          tooltip: 'Larger text',
          onPressed: noteSize < 22 ? () => setState(() => noteSize++) : null,
          icon: const Icon(Icons.text_increase),
        ),
      ]),
      NotesView(markup: t.notes, fontSize: noteSize),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Icon(Icons.speed, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(t.complexity, style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
      ),
      const SizedBox(height: 20),
      Builder(
        builder: (ctx) => FilledButton.icon(
          onPressed: () => DefaultTabController.of(ctx).animateTo(1),
          icon: const Icon(Icons.edit_note),
          label: const Text('Try the practice question'),
        ),
      ),
    ]);
  }

  Widget practiceTab() {
    final t = widget.lesson;
    final progress = _progressFor(widget.store, t);
    final done = progress?['done'] == true;
    final shown = ((progress?['hints'] as num?)?.toInt() ?? 0).clamp(0, t.hints.length);
    const labels = ['Gentle nudge', 'Bigger hint', 'Almost there'];
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.help_outline, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Question', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const Spacer(),
            if (done) const _Pill(icon: Icons.check_circle, iconColor: AppColors.success, label: 'Solved'),
          ]),
          const SizedBox(height: 10),
          SelectableText(t.question, style: const TextStyle(height: 1.55, fontSize: 16)),
        ]),
      ),
      const SizedBox(height: 20),
      Row(children: [
        const Text('Hints', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const Spacer(),
        Text('$shown of ${t.hints.length}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 8),
      for (var i = 0; i < shown; i++)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(i < labels.length ? labels[i] : 'Hint ${i + 1}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.warning)),
            const SizedBox(height: 4),
            Text(t.hints[i], style: const TextStyle(height: 1.5, fontSize: 15)),
          ]),
        ),
      if (shown < t.hints.length)
        OutlinedButton.icon(
          onPressed: () => _saveProgress(widget.store, t, {'hints': shown + 1}),
          icon: const Icon(Icons.lightbulb_outline),
          label: Text(shown == 0 ? 'Stuck? Show a gentle nudge' : 'Show the next hint'),
        ),
      const SizedBox(height: 20),
      const Text('Your answer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 8),
      TextField(
        controller: answer,
        minLines: 5,
        maxLines: 12,
        decoration: const InputDecoration(hintText: 'Write your approach, steps or pseudocode…'),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await _saveProgress(widget.store, t, {'answer': answer.text});
              toast('Answer saved');
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(onPressed: askTutor, icon: const Icon(Icons.auto_awesome), label: const Text('AI tutor')),
        ),
      ]),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () => toggleSolved(done),
        icon: Icon(done ? Icons.undo : Icons.check),
        label: Text(done ? 'Mark as not solved' : 'Mark as solved'),
      ),
    ]);
  }

  Widget labsTab() {
    final t = widget.lesson;
    IconData iconFor(String p) => switch (p) {
          'LeetCode' => Icons.code,
          'Kaggle' => Icons.auto_graph,
          'picoCTF' => Icons.flag,
          'TryHackMe' => Icons.terminal,
          _ => Icons.dns,
        };
    Color colorFor(String p) => switch (p) {
          'LeetCode' => AppColors.accent,
          'Kaggle' => AppColors.primary,
          'picoCTF' => AppColors.warning,
          'TryHackMe' => AppColors.danger,
          _ => AppColors.success,
        };
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
      Text(t.area == 'CTF' ? 'Hands-on labs' : (t.area == 'AI' ? 'Hands-on courses' : 'Practice problems'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(
          t.area == 'CTF'
              ? 'Practise this topic on real platforms. Only attack machines you are given.'
              : (t.area == 'AI' ? 'Free interactive notebooks to try it yourself.' : 'Solve these after the lesson, then revisit in a week.'),
          style: const TextStyle(color: AppColors.muted)),
      const SizedBox(height: 12),
      for (final p in t.practice)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: CircleAvatar(backgroundColor: colorFor(p.platform).withValues(alpha: 0.12), child: Icon(iconFor(p.platform), color: colorFor(p.platform))),
              title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(p.platform),
              trailing: const Icon(Icons.open_in_new, size: 20),
              onTap: () => launchUrl(Uri.parse(p.url), mode: LaunchMode.externalApplication),
            ),
          ),
        ),
      if (t.exam.isNotEmpty) ...[
        const SizedBox(height: 14),
        const Text('Exam alignment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Where this topic shows up in the CEH and Check Point CCSA syllabi.', style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 12),
        for (final e in t.exam)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: e.startsWith('CEH') ? AppColors.primarySoft : AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(e.startsWith('CEH') ? 'CEH' : 'CCSA',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: e.startsWith('CEH') ? AppColors.primary : AppColors.warning)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(e.split('·').last.trim(), style: const TextStyle(height: 1.4, fontWeight: FontWeight.w600))),
            ]),
          ),
      ],
    ]);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, this.iconColor = AppColors.muted});
  final IconData icon;
  final String label;
  final Color iconColor;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: icon == Icons.circle ? 9 : 15, color: iconColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});
  final Widget child;
  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// One specific video per topic, embedded in the lesson.
class LessonVideo extends StatefulWidget {
  const LessonVideo({super.key, required this.videoId, required this.title});
  final String videoId, title;
  @override
  State<LessonVideo> createState() => _LessonVideoState();
}

class _LessonVideoState extends State<LessonVideo> {
  late final YoutubePlayerController controller = YoutubePlayerController.fromVideoId(
    videoId: widget.videoId,
    autoPlay: false,
    params: const YoutubePlayerParams(showFullscreenButton: true, strictRelatedVideos: true),
  );

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: YoutubePlayer(controller: controller, aspectRatio: 16 / 9),
        ),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.play_lesson, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35))),
          TextButton(
            onPressed: () => launchUrl(Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}'), mode: LaunchMode.externalApplication),
            child: const Text('Open in YouTube'),
          ),
        ]),
      ]);
}

class CustomTimetablePage extends StatefulWidget {
  const CustomTimetablePage({super.key,required this.store});
  final WorkspaceStore store;
  @override State<CustomTimetablePage> createState()=>_CustomTimetablePageState();
}
class _CustomTimetablePageState extends State<CustomTimetablePage> {
  static const days=['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
  @override Widget build(BuildContext context) {
    final sessions=widget.store.ofKind('schedule')..sort((a,b){
      final d=days.indexOf(_str(a['day'])).compareTo(days.indexOf(_str(b['day'])));
      return d!=0?d:_str(a['startTime']).compareTo(_str(b['startTime']));
    });
    final grouped=<String,List<Map<String,dynamic>>>{for(final d in days)d:[]};
    for(final item in sessions){grouped.putIfAbsent(_str(item['day']),()=>[]).add(item);}
    return ListView(padding:const EdgeInsets.all(16),children:[
      const Text('My timetable',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800)),
      const Text('Build your own weekly routine. No default timetable is imposed.'),
      const SizedBox(height:12),
      FilledButton.icon(onPressed:()=>_edit(context),icon:const Icon(Icons.add),label:const Text('Add study session')),
      if(sessions.isEmpty) const Padding(padding:EdgeInsets.all(22),child:Text('Your timetable is empty. Add the days, times, subjects and goals that fit your routine.',textAlign:TextAlign.center))
      else ...days.where((d)=>grouped[d]!.isNotEmpty).map((d)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Padding(padding:const EdgeInsets.only(top:14,bottom:6),child:Text(d==days[DateTime.now().weekday-1]?d+' · Today':d,style:TextStyle(fontSize:16,fontWeight:FontWeight.w800,color:d==days[DateTime.now().weekday-1]?_accent:null))),
        ...grouped[d]!.map((item)=>Card(child:ListTile(
          leading:const Icon(Icons.schedule,color:_accent),
          title:Text(_str(item['title']),style:const TextStyle(fontWeight:FontWeight.w700)),
          subtitle:Text(_str(item['startTime'])+' · '+_str(item['duration'])+' min · '+_str(item['subject'])),
          trailing:PopupMenuButton<String>(onSelected:(v)=>v=='edit'?_edit(context,item:item):widget.store.remove(item),
            itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('Edit')),PopupMenuItem(value:'delete',child:Text('Delete'))]),
        ))),
      ])),
    ]);
  }
  Future<void> _edit(BuildContext context,{Map<String,dynamic>? item}) async {
    final title=TextEditingController(text:_str(item?['title']));
    final duration=TextEditingController(text:_str(item?['duration']).isEmpty?'60':_str(item?['duration']));
    var day=_str(item?['day']).isEmpty?'Monday':_str(item?['day']);
    var subject=_str(item?['subject']).isEmpty?'DSA':_str(item?['subject']);
    var time=_str(item?['startTime']).isEmpty?'18:00':_str(item?['startTime']);
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(
      title:Text(item==null?'Add study session':'Edit study session'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:title,decoration:const InputDecoration(labelText:'Session / goal')),
        DropdownButtonFormField<String>(value:day,decoration:const InputDecoration(labelText:'Day'),items:days.map((d)=>DropdownMenuItem(value:d,child:Text(d))).toList(),onChanged:(v)=>setDialog(()=>day=v??day)),
        DropdownButtonFormField<String>(value:subject,decoration:const InputDecoration(labelText:'Subject'),items:const ['CTF','DSA','AI/ML','Research','Revision','Contest','Other'].map((d)=>DropdownMenuItem(value:d,child:Text(d))).toList(),onChanged:(v)=>setDialog(()=>subject=v??subject)),
        ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.access_time),title:const Text('Start time'),trailing:Text(time,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:16)),onTap:() async {
          final parts=time.split(':');
          final picked=await showTimePicker(context:ctx,initialTime:TimeOfDay(hour:int.parse(parts[0]),minute:int.parse(parts[1])));
          if(picked!=null) setDialog(()=>time=picked.hour.toString().padLeft(2,'0')+':'+picked.minute.toString().padLeft(2,'0'));
        }),
        TextField(controller:duration,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Duration in minutes')),
      ])),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,title.text.trim().isNotEmpty&&RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(time)&&int.tryParse(duration.text)!=null&&int.parse(duration.text)>0),child:const Text('Save')),
      ],
    )));
    if(ok==true){
      await widget.store.upsert({'id':item?['id']??newWorkspaceId(),'kind':'schedule','title':title.text.trim(),'day':day,'subject':subject,'startTime':time,'duration':int.parse(duration.text)});
    }
    title.dispose();duration.dispose();
  }
}