import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/lessons.dart';
import '../data/workspace_store.dart';

const Color _accent = Color(0xFF7665D8);
String _str(dynamic value) => value?.toString() ?? '';

Map<String, dynamic>? _progressFor(WorkspaceStore store, Lesson lesson) {
  for (final entry in store.ofKind('lesson')) {
    if (entry['id'] == lesson.id) return entry;
  }
  return null;
}

Future<void> _saveProgress(
    WorkspaceStore store, Lesson lesson, Map<String, dynamic> changes) {
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

Color _levelColor(String level) {
  switch (level) {
    case 'Advanced':
      return Colors.red.shade400;
    case 'Intermediate':
      return Colors.orange.shade700;
    default:
      return Colors.green.shade600;
  }
}

class StudyPage extends StatefulWidget {
  const StudyPage({super.key, required this.store});
  final WorkspaceStore store;
  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  String area = 'CTF', level = 'All', query = '';

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final inArea = lessons.where((t) => t.area == area).toList();
    final solved =
        inArea.where((t) => _progressFor(store, t)?['done'] == true).length;
    final q = query.trim().toLowerCase();
    final list = inArea
        .where((t) => level == 'All' || t.level == level)
        .where((t) =>
            q.isEmpty ||
            t.title.toLowerCase().contains(q) ||
            t.question.toLowerCase().contains(q))
        .toList();
    final fraction = inArea.isEmpty ? 0.0 : solved / inArea.length;

    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [
      const Text('Study',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text('Try the question, reveal hints one at a time, then read the notes or watch a video.',
          style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
      const SizedBox(height: 14),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'CTF', label: Text('CTF'), icon: Icon(Icons.security)),
          ButtonSegment(value: 'DSA', label: Text('DSA'), icon: Icon(Icons.code)),
        ],
        selected: {area},
        onSelectionChanged: (v) => setState(() => area = v.first),
      ),
      const SizedBox(height: 14),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text('$area progress',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              Text('$solved of ${inArea.length} solved',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: _accent)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: fraction, minHeight: 9),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search), hintText: 'Search topics'),
        onChanged: (v) => setState(() => query = v),
      ),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final l in const ['All', 'Beginner', 'Intermediate', 'Advanced'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(l),
                selected: level == l,
                onSelected: (_) => setState(() => level = l),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 8),
      if (list.isEmpty)
        const Padding(
          padding: EdgeInsets.all(28),
          child: Text('No matching topic. Try another keyword or level.',
              textAlign: TextAlign.center),
        )
      else
        ...list.map((t) => _LessonTile(
              lesson: t,
              progress: _progressFor(store, t),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => LessonPage(lesson: t, store: store))),
            )),
      const SizedBox(height: 8),
      Text(
          'Everything here works offline. Your progress and answers sync with your account.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
    ]);
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.progress, required this.onTap});
  final Lesson lesson;
  final Map<String, dynamic>? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = progress?['done'] == true;
    final hintsUsed = (progress?['hints'] as num?)?.toInt() ?? 0;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: done ? Colors.green.shade50 : const Color(0xFFEFEAFB),
          child: Icon(done ? Icons.check_circle : Icons.play_arrow_rounded,
              color: done ? Colors.green.shade700 : _accent),
        ),
        title: Text(lesson.title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            Icon(Icons.circle, size: 9, color: _levelColor(lesson.level)),
            const SizedBox(width: 5),
            Text(lesson.level),
            const SizedBox(width: 12),
            Text('Hints $hintsUsed/${lesson.hints.length}'),
          ]),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class LessonPage extends StatefulWidget {
  const LessonPage({super.key, required this.lesson, required this.store});
  final Lesson lesson;
  final WorkspaceStore store;
  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  late final TextEditingController answer;

  @override
  void initState() {
    super.initState();
    answer = TextEditingController(
        text: _str(_progressFor(widget.store, widget.lesson)?['answer']));
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

  Future<void> askGpt() async {
    final t = widget.lesson;
    final attempt = answer.text.trim();
    final prompt = 'Act as a patient ' +
        (t.area == 'CTF' ? 'cybersecurity CTF' : 'DSA') +
        ' tutor. Topic: ' + t.title +
        '. Question: ' + t.question +
        (attempt.isEmpty ? '' : ' My attempt so far: ' + attempt) +
        ' Give one hint at a time and do not reveal the full solution until I ask. Then explain the concept, approach, edge cases, and complexity.';
    await Clipboard.setData(ClipboardData(text: prompt));
    toast('Tutor prompt copied. Paste it into ChatGPT or Claude.');
  }

  Future<void> openVideo() async {
    final uri = Uri.parse('https://www.youtube.com/results?search_query=' +
        Uri.encodeComponent(widget.lesson.videoQuery));
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) toast('Could not open the video link.');
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.lesson;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w800)),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'Practice'),
            Tab(icon: Icon(Icons.menu_book_outlined), text: 'Notes & video'),
          ]),
        ),
        body: AnimatedBuilder(
          animation: widget.store,
          builder: (context, _) => TabBarView(children: [
            practiceTab(context),
            notesTab(context),
          ]),
        ),
      ),
    );
  }

  Widget practiceTab(BuildContext context) {
    final t = widget.lesson;
    final progress = _progressFor(widget.store, t);
    final done = progress?['done'] == true;
    final shown = ((progress?['hints'] as num?)?.toInt() ?? 0).clamp(0, t.hints.length);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [
      Wrap(spacing: 8, children: [
        Chip(label: Text(t.area), avatar: Icon(t.area == 'CTF' ? Icons.security : Icons.code, size: 16)),
        Chip(label: Text(t.level), avatar: Icon(Icons.circle, size: 10, color: _levelColor(t.level))),
        if (done) Chip(label: const Text('Solved'), avatar: Icon(Icons.check_circle, size: 16, color: Colors.green.shade700)),
      ]),
      const SizedBox(height: 8),
      const Text('Question', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 6),
      SelectableText(t.question, style: const TextStyle(height: 1.5, fontSize: 15)),
      const SizedBox(height: 18),
      Row(children: [
        const Expanded(
          child: Text('Hints', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
        Text('$shown / ${t.hints.length} revealed', style: TextStyle(color: Colors.grey.shade700)),
      ]),
      const SizedBox(height: 6),
      for (var i = 0; i < shown; i++)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFEAFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('Hint ${i + 1}: ${t.hints[i]}', style: const TextStyle(height: 1.45)),
        ),
      OutlinedButton.icon(
        onPressed: shown < t.hints.length
            ? () => _saveProgress(widget.store, t, {'hints': shown + 1})
            : null,
        icon: const Icon(Icons.lightbulb_outline),
        label: Text(shown == 0
            ? 'Reveal first hint'
            : shown < t.hints.length
                ? 'Reveal next hint'
                : 'All hints revealed'),
      ),
      const SizedBox(height: 18),
      const Text('Your answer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 6),
      TextField(
        controller: answer,
        minLines: 4,
        maxLines: 10,
        decoration: const InputDecoration(
            hintText: 'Write your approach, steps or pseudocode here…'),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await _saveProgress(widget.store, t, {'answer': answer.text});
              toast('Answer saved');
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save answer'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: askGpt,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Ask AI tutor'),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _saveProgress(
              widget.store, t, {'done': !done, 'answer': answer.text}),
          icon: Icon(done ? Icons.undo : Icons.check),
          label: Text(done ? 'Mark as not solved' : 'Mark as solved'),
        ),
      ),
    ]);
  }

  Widget notesTab(BuildContext context) {
    final t = widget.lesson;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [
      Card(
        child: ListTile(
          leading: const Icon(Icons.ondemand_video, color: _accent),
          title: const Text('Watch while you read',
              style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text(
              'Opens video results. Use Android split-screen to keep these notes beside the video.'),
          trailing: const Icon(Icons.open_in_new),
          onTap: openVideo,
        ),
      ),
      const SizedBox(height: 8),
      ..._formatNotes(t.notes),
      _callout('Solution approach', t.approach, Icons.route),
      _callout('Complexity and analysis', t.complexity, Icons.speed),
    ]);
  }

  Widget _callout(String title, String body, IconData icon) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFEAFB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: _accent),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 6),
          SelectableText(body, style: const TextStyle(height: 1.45)),
        ]),
      );

  // Turns the plain-text notes into headed sections with readable steps.
  List<Widget> _formatNotes(String notes) {
    final widgets = <Widget>[];
    final heading = RegExp(r'^[A-Z0-9 /&()\-.]{3,}$');
    for (final block in notes.split('\n\n')) {
      final lines = block.split('\n');
      var body = lines;
      if (lines.isNotEmpty && heading.hasMatch(lines.first.trim())) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(lines.first.trim(),
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.8, color: _accent)),
        ));
        body = lines.sublist(1);
      }
      for (final line in body) {
        if (line.trim().isEmpty) continue;
        final isStep = RegExp(r'^(\d+\.|-)\s').hasMatch(line.trim());
        widgets.add(Padding(
          padding: EdgeInsets.only(top: 4, left: isStep ? 8 : 0),
          child: SelectableText(line.trim(), style: const TextStyle(height: 1.5, fontSize: 15)),
        ));
      }
    }
    return widgets;
  }
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
        DropdownButtonFormField<String>(value:subject,decoration:const InputDecoration(labelText:'Subject'),items:const ['CTF','DSA','Research','Revision','Contest','Other'].map((d)=>DropdownMenuItem(value:d,child:Text(d))).toList(),onChanged:(v)=>setDialog(()=>subject=v??subject)),
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