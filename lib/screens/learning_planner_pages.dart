import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/workspace_store.dart';

const Color _accent = Color(0xFF7665D8);
String _str(dynamic value) => value?.toString() ?? '';

class _Lesson {
  const _Lesson(this.area, this.title, this.question, this.hints, this.notes,
      this.approach, this.complexity, this.videoQuery);
  final String area, title, question, notes, approach, complexity, videoQuery;
  final List<String> hints;
}

const List<_Lesson> _lessons = [
  _Lesson('CTF','Web: SQL injection',
    'A training web app concatenates a username into a SQL query. Explain how to test for SQL injection in an authorized lab, identify the root cause, and recommend a safe fix.',
    ['Trace untrusted input from the HTTP request to the database query.','In a local lab, compare normal input with harmless quote and boolean probes; observe response differences.','The root cause is mixing query syntax with user data. Use prepared statements and bound parameters.'],
    'WHAT IT IS\nSQL injection happens when untrusted input is interpreted as SQL syntax instead of data.\n\nINVESTIGATION\n1. Trace the parameter from the request handler to the database call.\n2. Identify string concatenation or interpolation in query construction.\n3. Reproduce only in an intentionally vulnerable local lab.\n4. Compare response behavior and preserve a minimal test case.\n5. Never test systems without permission or extract real data.\n\nPREVENTION\nUse prepared statements with bound parameters, least-privilege database accounts, safe error handling, and regression tests. Input validation does not replace parameterization.\n\nKEY TAKEAWAY\nKeep code and data separate. Parameterization preserves the intended SQL structure.',
    'Trace input → query construction → database execution. Reproduce safely, replace concatenation with bound parameters, and add a regression test.',
    'Not an algorithm exercise. Evaluate exploitability and remediation in a controlled lab.',
    'SQL injection explained prepared statements PortSwigger Web Security Academy'),
  _Lesson('CTF','Crypto: XOR',
    'A ciphertext is believed to use single-byte XOR. Describe a systematic recovery method and explain why repeating-key XOR is not suitable for modern secure communication.',
    ['Applying the same XOR key twice restores the original byte.','Try all 256 possible one-byte keys and score outputs for printable text and language patterns.','For repeating-key XOR, estimate key length from repeating structure, then solve each key position.'],
    'XOR PROPERTY\nFor plaintext P and key K, ciphertext C = P XOR K. Decryption is P = C XOR K because K XOR K = 0.\n\nCTF WORKFLOW\n1. Identify whether the ciphertext is hex, Base64, or raw bytes.\n2. Decode the representation before cryptanalysis.\n3. Enumerate all 256 single-byte keys.\n4. Rank candidates using printable-character ratio, spaces, and letter frequencies.\n5. Inspect the best candidates in the challenge context.\n\nREPEATING-KEY XOR\nRepeated key bytes create periodic structure. Estimate likely key lengths, split bytes by key position, and solve each column as a single-byte XOR problem.\n\nMODERN CRYPTOGRAPHY\nXOR is a primitive, not a secure encryption design by itself. Key reuse and missing authentication are weaknesses. Use vetted authenticated encryption such as AES-GCM or ChaCha20-Poly1305 with correct nonce handling.',
    'Decode the transport format, brute-force the one-byte key, rank readable outputs, and validate the candidate against the challenge.',
    'Single-byte brute force performs 256 × n byte operations: O(n) for a fixed key space.',
    'single byte XOR cryptography CTF walkthrough'),
  _Lesson('CTF','Forensics: file signatures',
    'A file has an unfamiliar extension and will not open. Explain how to identify its real type, check for truncation or embedded data, and preserve evidence integrity.',
    ['Do not trust the filename extension; inspect bytes at the beginning and end.','Use file identification and a hex viewer to compare magic bytes with known formats.','Analyze a copy, hash the original, and document every extraction or transformation.'],
    'FILE SIGNATURES\nFile formats often contain recognizable magic bytes. A PNG begins with 89 50 4E 47 0D 0A 1A 0A. An extension is only a filename label and can be changed.\n\nREPEATABLE WORKFLOW\n1. Preserve the original and record source, time, and SHA-256 hash.\n2. Work on a verified copy; identify it with file and a hex viewer.\n3. Inspect headers, trailers, metadata, and expected internal structure.\n4. Check for appended data, embedded files, and truncation.\n5. Extract to a separate directory and hash extracted objects.\n6. Record commands, tool versions, and findings.\n\nTOOLS\nfile, xxd, strings, exiftool, binwalk, and format-specific validators. Treat extracted content as untrusted.\n\nEVIDENCE HANDLING\nNever modify original evidence. Record hashes before and after acquisition and analysis.',
    'Preserve → hash → identify signature → inspect structure → extract from a copy → hash and document.',
    'Most inspection is linear in file size. Evidence provenance and reproducibility are essential.',
    'digital forensics file signatures magic bytes binwalk tutorial'),
  _Lesson('CTF','Linux permissions and privilege boundaries',
    'In a local Linux privilege-escalation lab, a service has excessive permissions. Explain how to audit permissions and service configuration, then recommend defensive fixes.',
    ['Start with identity, group membership, and the service account.','Inspect privileged service files, writable executable paths, sudo policy, and capabilities.','Apply least privilege, secure ownership and permissions, and monitor sensitive changes.'],
    'LINUX PERMISSIONS\nFiles have an owner, group, and read/write/execute mode bits. SUID, SGID, and Linux capabilities can alter process privileges.\n\nDEFENSIVE AUDIT\n- Review users, groups, sudo policy, and service accounts.\n- Check ownership and write permissions on service binaries, scripts, configuration, and parent directories.\n- Inspect systemd unit files and environment files for unsafe paths and exposed secrets.\n- Review SUID/SGID binaries and file capabilities; justify every exception.\n- Check PATH handling and writable directories used by privileged services.\n\nREMEDIATION\nUse dedicated non-login service accounts, least privilege, root-owned service code and configuration, restrictive directory permissions, pinned executable paths, and timely patching. Monitor privileged-file changes.\n\nLAB SAFETY\nUse intentionally vulnerable VMs or CTF instances you are authorized to test.',
    'Enumerate identity and permissions, trace the privileged execution path, validate the misconfiguration safely, and remediate least-privilege violations.',
    'Audit effort depends on host size. Prioritize privileged assets and document scope.',
    'Linux privilege escalation fundamentals permissions capabilities defensive audit'),
  _Lesson('CTF','Network analysis: PCAP triage',
    'Given a PCAP from a simulated incident, outline a repeatable process to identify endpoints, protocols, suspicious conversations, and a timeline without treating every anomaly as malicious.',
    ['Begin with capture metadata, packet counts, and protocol hierarchy.','Build a baseline of endpoints and conversations before inspecting individual streams.','Correlate DNS, timing, byte counts, and payload indicators with context.'],
    'PCAP TRIAGE\n1. Preserve the capture and compute a SHA-256 hash.\n2. Inspect duration, packet count, interface metadata, and truncation.\n3. Use Protocol Hierarchy and Conversations to understand traffic shape.\n4. Review DNS, HTTP, TLS metadata, SMB, and unusual ports where relevant.\n5. Follow selected streams and extract indicators without executing payloads.\n6. Build a timeline with timestamps, endpoints, protocol, and packet references.\n7. Correlate with endpoint or server logs before concluding.\n\nUSEFUL FILTERS\nExamples: dns, http, tcp.stream eq 4, ip.addr == 10.0.0.5. Filters narrow the view; they do not prove maliciousness.\n\nREPORTING\nSeparate observations from hypotheses, include packet numbers and timestamps, and state capture limitations.',
    'Metadata → protocol hierarchy → conversations → targeted streams → timeline → corroboration.',
    'Review effort scales with capture size. Filtering and indexing reduce analyst effort.',
    'Wireshark PCAP analysis beginner incident response tutorial'),
  _Lesson('CTF','Web reconnaissance and HTTP',
    'For an authorized web CTF target, design a low-impact reconnaissance plan that maps routes, technologies, and input points without destructive testing.',
    ['Define exact scope, exclusions, and request limits before testing.','Inspect site links, robots.txt, response headers, cookies, forms, and static assets.','Record routes and parameters; prioritize manual validation over noisy scans.'],
    'RECON GOALS\nCreate an accurate map of the application surface, not simply large scan output.\n\nWORKFLOW\n1. Confirm the exact host, scope, exclusions, and permitted request rate.\n2. Browse normally and record routes, forms, parameters, and authentication boundaries.\n3. Inspect headers, cookies, redirects, and static assets.\n4. Review robots.txt and sitemap as clues, not as authorization.\n5. Use Burp Suite or OWASP ZAP to understand requests and responses.\n6. Test only hypotheses allowed by the CTF rules; avoid destructive payloads and denial-of-service behavior.\n\nDELIVERABLE\nA route inventory, input-point list, technology clues, and prioritized hypotheses with evidence.',
    'Scope → browse → map routes and parameters → inspect HTTP behavior → prioritize safe tests.',
    'Keep requests bounded. Quality of notes matters more than request volume.',
    'web application reconnaissance HTTP Burp Suite beginner CTF'),
  _Lesson('DSA','Arrays and hash maps',
    'Given an integer array and a target, return the indices of two distinct elements whose values add to the target. Explain an efficient solution.',
    ['Brute force checks every pair. What information would avoid scanning all earlier elements?','For each value x, the required partner is target - x. Store previously seen values and indices.','Check the complement before inserting the current value so one index is not reused.'],
    'ARRAYS\nArrays store elements in indexed order. Index access is O(1); searching is O(n); inserting in the middle may require shifting.\n\nHASH MAPS\nA hash map stores key-value pairs and provides average O(1) lookup and insertion.\n\nTWO SUM PATTERN\nScan left to right. For each index i, compute need = target - nums[i]. If need exists in the map, return its stored index and i. Otherwise store nums[i] with index i.\n\nCORRECTNESS\nWhen the second member of a valid pair is reached, the first has already been stored. Checking before insertion prevents reusing the same index.\n\nCOMPLEXITY\nTime O(n) average; space O(n). Brute force uses O(n²) time and O(1) extra space.\n\nCOMMON ERRORS\nInserting before checking, returning values instead of indices, or forgetting distinct positions.',
    'Use a map from value to index. For each element, check its complement, then insert the current element.',
    'O(n) average time and O(n) extra space.',
    'Two Sum arrays hash map DSA explained'),
  _Lesson('DSA','Two pointers',
    'Given a sorted integer array, determine whether two distinct elements sum to a target. Return their indices or report that none exists.',
    ['Sorting provides an ordering relationship you can use.','Start one pointer at each end and compare the current sum with the target.','If too small move left forward; if too large move right backward.'],
    'TECHNIQUE\nTwo pointers move through a sequence while maintaining an invariant. It is useful for sorted arrays, pairs, partitions, and in-place transformations.\n\nSORTED PAIR SUM\nSet left = 0 and right = n - 1. While left < right, calculate the sum. If equal, return. If sum < target, increment left; otherwise decrement right.\n\nWHY IT WORKS\nBecause the array is sorted, increasing the left value is the useful way to increase a too-small sum. Decreasing the right value reduces a too-large sum. Discarded pairs cannot become a solution later.\n\nCOMPLEXITY\nO(n) time and O(1) extra space.\n\nVARIANTS\nRemove duplicates, Container With Most Water, 3Sum after sorting, merge sorted arrays, and partitioning.',
    'Maintain left < right; move the pointer that can bring the sum toward the target.',
    'O(n) time and O(1) extra space.',
    'two pointers technique DSA sorted array tutorial'),
  _Lesson('DSA','Sliding window',
    'Given a positive-integer array and a positive target, find the minimum length of a contiguous subarray whose sum is at least the target. Return 0 if none exists.',
    ['A subarray is contiguous; a subsequence need not be.','Expand the right edge to increase the sum. Once the sum reaches target, shrink from the left.','Positivity makes the expand/shrink process monotonic.'],
    'SLIDING WINDOW\nMaintain a contiguous range [left, right] and update it incrementally instead of recomputing every subarray.\n\nVARIABLE WINDOW\nFor each right index, add nums[right] to the running sum. While sum >= target, update the best length, subtract nums[left], and increment left.\n\nWHY POSITIVITY MATTERS\nWith positive values, moving right never decreases the sum and moving left never increases it. This monotonic behavior makes the greedy process valid.\n\nCOMPLEXITY\nEach index enters and leaves the window at most once: O(n) time and O(1) extra space.\n\nIMPORTANT CAVEAT\nThis exact method does not work for arbitrary negative values. For negatives, consider prefix sums with a monotonic deque.',
    'Expand right, then repeatedly shrink left while the condition remains satisfied.',
    'O(n) time and O(1) extra space for positive values.',
    'sliding window variable size DSA minimum subarray length'),
  _Lesson('DSA','Binary search',
    'Given a sorted array of distinct integers and a target, return its index or -1 if absent. Explain the loop invariant and off-by-one safety.',
    ['The answer, if present, remains inside a shrinking search interval.','Compare with the middle element and discard the half that cannot contain the target.','For a closed interval use left <= right, then update to mid - 1 or mid + 1.'],
    'PREREQUISITE\nThe search space must be ordered or the predicate must be monotonic.\n\nCLOSED INTERVAL\nInitialize left = 0 and right = n - 1. While left <= right, compute mid = left + (right - left) / 2. If equal, return mid. If target is smaller, set right = mid - 1; otherwise set left = mid + 1.\n\nINVARIANT\nIf the target exists, it remains within [left, right]. Each iteration strictly reduces the interval.\n\nCOMPLEXITY\nO(log n) time and O(1) extra space.\n\nVARIANTS\nLower bound, upper bound, first/last occurrence, rotated arrays, and binary search on a monotonic answer predicate.',
    'Maintain a valid interval and discard exactly the half proven not to contain the target.',
    'O(log n) time and O(1) extra space.',
    'binary search loop invariant lower bound DSA tutorial'),
  _Lesson('DSA','Stacks and monotonic stacks',
    'Given a string containing only brackets, determine whether the bracket sequence is valid. Explain how a stack models nested structure.',
    ['A closing bracket must match the most recent unmatched opening bracket.','Push opening brackets; on a closing bracket, check the top and pop.','At the end, validity also requires the stack to be empty.'],
    'STACK\nA stack is last-in, first-out. Push and pop are O(1) amortized for a dynamic-array implementation.\n\nBRACKET VALIDATION\nPush opening brackets. For a closing bracket, reject if the stack is empty or the top does not match; otherwise pop. At the end, accept only if the stack is empty.\n\nWHY IT WORKS\nNested structures close in reverse order of opening, matching LIFO behavior.\n\nCOMPLEXITY\nO(n) time and O(n) worst-case space.\n\nMONOTONIC STACK\nA monotonic stack maintains increasing or decreasing values to solve next-greater-element, daily temperatures, and histogram-area problems in linear time.',
    'Use a stack of opening brackets; validate and pop on each closing bracket.',
    'O(n) time and O(n) extra space.',
    'stack data structure valid parentheses monotonic stack DSA'),
  _Lesson('DSA','Trees: DFS and BFS',
    'Given a binary tree, return its level-order traversal as a list of levels. Explain why a queue is appropriate and compare DFS.',
    ['Level-order traversal visits nodes in increasing distance from the root.','Use a FIFO queue and capture its size before processing each level.','Process exactly that many nodes, enqueueing their children for the next level.'],
    'TREE TERMS\nA binary tree node has at most two children. Depth is distance from the root; height is the longest downward path to a leaf.\n\nBFS LEVEL ORDER\nInitialize a queue with the root. While non-empty, record the current queue size, process exactly that many nodes, append values to the current level, and enqueue non-null children.\n\nWHY A QUEUE\nFIFO order ensures all nodes at depth d are processed before nodes at depth d+1.\n\nDFS COMPARISON\nPreorder: node, left, right. Inorder: left, node, right. Postorder: left, right, node. DFS uses recursion or an explicit stack; BFS uses a queue.\n\nCOMPLEXITY\nBoth traverse O(n) nodes. BFS uses O(w) queue space where w is maximum width; DFS uses O(h) stack space where h is height.',
    'Queue the root; process one fixed queue-size batch per level and enqueue children.',
    'O(n) time; O(w) auxiliary space for BFS.',
    'binary tree BFS level order traversal DFS DSA'),
  _Lesson('DSA','Graphs: BFS and DFS',
    'Given an undirected graph and a source vertex, determine all vertices reachable from the source. Explain visited-set handling and compare BFS with DFS.',
    ['A graph may contain cycles, so remember which vertices have already been visited.','BFS uses a queue; DFS uses recursion or a stack.','Mark a vertex visited when enqueuing or pushing it to avoid duplicate work.'],
    'REPRESENTATION\nAdjacency lists store each vertex and its neighbors. An undirected edge appears in both endpoint lists.\n\nBFS\nUse a queue. Mark the source visited, then remove a vertex and enqueue each unvisited neighbor. BFS discovers vertices in nondecreasing edge distance.\n\nDFS\nUse recursion or a stack to explore one path deeply before backtracking. DFS is useful for connected components, cycle detection, and topological-sort foundations.\n\nCOMPLEXITY\nWith adjacency lists, BFS and DFS take O(V + E) time and O(V) auxiliary space.\n\nCOMMON ERRORS\nForgetting visited tracking, marking too late, assuming the graph is connected, and confusing directed with undirected edges.',
    'Traverse from the source using BFS or DFS and mark every vertex once.',
    'O(V + E) time and O(V) extra space.',
    'graph BFS DFS adjacency list DSA tutorial')
];

class StudyPage extends StatefulWidget {
  const StudyPage({super.key, required this.store});
  final WorkspaceStore store;
  @override State<StudyPage> createState() => _StudyPageState();
}
class _StudyPageState extends State<StudyPage> {
  String area = 'CTF', query = '';
  @override Widget build(BuildContext context) {
    final list = _lessons.where((t) => t.area == area &&
      (t.title.toLowerCase().contains(query.toLowerCase()) ||
       t.question.toLowerCase().contains(query.toLowerCase()))).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Guided learning', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      const Text('Questions, progressive hints, detailed notes and video lessons.'),
      const SizedBox(height: 12),
      SegmentedButton<String>(segments: const [
        ButtonSegment(value:'CTF', label:Text('CTF'), icon:Icon(Icons.security)),
        ButtonSegment(value:'DSA', label:Text('DSA'), icon:Icon(Icons.code)),
      ], selected:{area}, onSelectionChanged:(v)=>setState(()=>area=v.first)),
      const SizedBox(height:10),
      TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search topics',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>query=v)),
      const SizedBox(height:10),
      if(list.isEmpty) const Text('No matching topic. Try another keyword.')
      else ...list.map((t)=>_LessonCard(lesson:t)),
      const Text('The library works offline. Ask GPT copies a structured tutoring prompt so learners can request another question or explanation.',style:TextStyle(fontSize:11,color:Colors.black54)),
    ]);
  }
}

class _LessonCard extends StatefulWidget {
  const _LessonCard({required this.lesson});
  final _Lesson lesson;
  @override State<_LessonCard> createState()=>_LessonCardState();
}
class _LessonCardState extends State<_LessonCard> {
  int hints=0;
  bool notes=false;
  @override Widget build(BuildContext context) {
    final t=widget.lesson;
    return Card(margin:const EdgeInsets.only(bottom:12),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text(t.title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16))),Chip(label:Text(t.area))]),
      const Text('Practice question',style:TextStyle(fontWeight:FontWeight.w700)),
      const SizedBox(height:5),Text(t.question,style:const TextStyle(height:1.4)),
      const SizedBox(height:8),
      Wrap(spacing:8,children:[
        OutlinedButton.icon(onPressed:hints<t.hints.length?()=>setState(()=>hints++):null,icon:const Icon(Icons.lightbulb_outline),label:Text(hints==0?'Show hint':'Next hint')),
        OutlinedButton.icon(onPressed:() async {
          final prompt='Act as a patient '+(t.area=='CTF'?'cybersecurity CTF':'DSA')+' tutor. Topic: '+t.title+'. Question: '+t.question+'. Give one hint at a time and do not reveal the full solution until requested. Then explain the concept, approach, edge cases, and complexity.';
          await Clipboard.setData(ClipboardData(text:prompt));
          if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('GPT prompt copied')));
        },icon:const Icon(Icons.chat_bubble_outline),label:const Text('Ask GPT')),
      ]),
      if(hints>0) Container(width:double.infinity,padding:const EdgeInsets.all(10),margin:const EdgeInsets.only(top:8),decoration:BoxDecoration(color:const Color(0xFFEFEAFB),borderRadius:BorderRadius.circular(10)),child:Text('Hint '+hints.toString()+' of '+t.hints.length.toString()+': '+t.hints[hints-1])),
      const Divider(height:20),
      TextButton.icon(onPressed:()=>setState(()=>notes=!notes),icon:Icon(notes?Icons.expand_less:Icons.menu_book_outlined),label:Text(notes?'Hide detailed notes':'Read detailed notes')),
      if(notes)...[
        SelectableText(t.notes,style:const TextStyle(height:1.48)),
        const SizedBox(height:8),
        const Text('Solution approach',style:TextStyle(fontWeight:FontWeight.w800)),SelectableText(t.approach),
        const SizedBox(height:6),
        const Text('Complexity / analysis',style:TextStyle(fontWeight:FontWeight.w800)),SelectableText(t.complexity),
      ],
      const SizedBox(height:6),
      OutlinedButton.icon(onPressed:()=>_openVideo(t.videoQuery),icon:const Icon(Icons.ondemand_video),label:const Text('Find a video lesson')),
    ])));
  }
}
Future<void> _openVideo(String query) async {
  final uri=Uri.parse('https://www.youtube.com/results?search_query='+Uri.encodeComponent(query));
  await launchUrl(uri,mode:LaunchMode.externalApplication);
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
        Padding(padding:const EdgeInsets.only(top:14,bottom:6),child:Text(d,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800))),
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
        TextFormField(initialValue:time,decoration:const InputDecoration(labelText:'Start time (24-hour HH:MM)'),onChanged:(v)=>time=v),
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