// Study library: questions, progressive hints, structured notes with
// diagrams, and one hand-picked video per topic.
//
// Notes use a small markup rendered by NotesView:
//   # Heading            - bullet            1. numbered step
//   > tip callout        ! warning callout   ``` code block ```
//   [flow] A -> B -> C                       vertical flow diagram
//   [array] 2,7,11,15 | 0:L,3:R | 1-2        cells, pointer labels, highlight
//   [bytes] 89 50 4E 47 | caption            hex byte strip
//   [tree] 3,9,20,null,null,15,7             binary tree (level order)
//   [graph] A-B,A-C,B-D,C-E                  undirected graph
//   [stack] ( [ {                            stack, last item is the top
//   [list] 1,2,3,4                           linked list
//   [table] H1|H2 ; a|b ; c|d                table, first row is header
//   [perm] -rwsr-xr--                        Linux permission breakdown

import 'lessons_more.dart';

/// Every topic in the app: core DSA + CTF, extra DSA, and the AI/ML/DL track.
const List<Lesson> lessons = [...coreLessons, ...extraDsaLessons, ...aiLessons];

class Lesson {
  const Lesson({
    required this.area,
    required this.title,
    required this.summary,
    required this.question,
    required this.hints,
    required this.notes,
    required this.keyPoints,
    required this.complexity,
    required this.videoId,
    required this.videoTitle,
    this.level = 'Beginner',
    this.minutes = 15,
    this.exam = const [],
    this.practice = const [],
  });

  /// Certification objectives this topic supports, e.g. CEH and CCSA.
  final List<String> exam;

  /// Hands-on rooms and challenges on HTB, TryHackMe and picoCTF.
  final List<PracticeLink> practice;

  final String area, title, summary, question, notes, complexity;
  final String videoId, videoTitle, level;
  final List<String> hints, keyPoints;
  final int minutes;

  String get id =>
      'lesson-' + title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
}

class PracticeLink {
  const PracticeLink(this.platform, this.title, this.url);
  final String platform, title, url;
}

const _pico = 'https://play.picoctf.org/practice?category=';

const List<Lesson> coreLessons = [
  // ───────────────────────────── DSA ─────────────────────────────
  Lesson(
    area: 'DSA',
    title: 'Arrays and hash maps',
    summary: 'Trade a little memory for instant lookups.',
    level: 'Beginner',
    minutes: 15,
    question:
        'Given an integer array nums and a target, return the indices of the two different elements that add up to target.',
    hints: [
      'Checking every pair works but is slow. What would let you skip the inner loop?',
      'For each value x you need target - x. Can you remember the values you have already seen?',
      'Check for the complement before storing the current value, so you never pair an element with itself.',
    ],
    notes: r'''
# The idea
An array gives O(1) access by index, but finding a value means scanning it. A hash map flips that: it finds a value in O(1) on average.

# Walkthrough: nums = [2, 7, 11, 15], target = 9
[array] 2,7,11,15 | 0:i=0,1:i=1 | 0-1
1. i = 0, value 2: need 7. Map is empty, so store {2: 0}.
2. i = 1, value 7: need 2. 2 is in the map at index 0.
3. Return [0, 1].

[table] Step|Value|Need|Map before|Result ; 1|2|7|{}|store 2→0 ; 2|7|2|{2:0}|found → [0,1]

# Algorithm
```
seen = {}
for i, x in enumerate(nums):
    need = target - x
    if need in seen:
        return [seen[need], i]
    seen[x] = i
```

> Check first, then insert. That single ordering choice prevents using the same index twice.

! Return indices, not values, and remember duplicates such as [3, 3] with target 6.
''',
    keyPoints: [
      'Map value → index while scanning once.',
      'Brute force is O(n²); the map makes it O(n).',
      'Check the complement before inserting.',
    ],
    complexity: 'Time O(n) average · Space O(n)',
    videoId: 'PTB0eIePbZo',
    videoTitle: 'Two Sum I & II: brute force, hash map and two pointers',
  ),
  Lesson(
    area: 'DSA',
    title: 'Two pointers',
    summary: 'Use sorted order to shrink the search from both ends.',
    level: 'Beginner',
    minutes: 15,
    question:
        'Given a sorted array and a target, find two different elements whose sum equals target and return their indices.',
    hints: [
      'The array is sorted. How can that tell you which way to move?',
      'Start one pointer at each end and look at their sum.',
      'Sum too small → move left forward. Sum too big → move right backward.',
    ],
    notes: r'''
# The idea
Place a pointer at each end. Because the array is sorted, every comparison tells you which pointer to move, so you never revisit a pair.

# Walkthrough: [1, 3, 4, 6, 9], target = 10
[array] 1,3,4,6,9 | 0:L,4:R
1. 1 + 9 = 10 → found. If it were too small, L moves right; too big, R moves left.

[array] 1,3,4,6,9 | 1:L,3:R | 1-3
2. Another example, target 9: 3 + 6 = 9 after moving both pointers inward.

# Decision rule
[flow] Compute sum = a[L] + a[R] -> sum == target? Return -> sum < target? L += 1 -> sum > target? R -= 1

# Algorithm
```
L, R = 0, len(a) - 1
while L < R:
    s = a[L] + a[R]
    if s == target: return [L, R]
    if s < target: L += 1
    else: R -= 1
```

> Same pattern also solves: remove duplicates, container with most water, 3Sum (after sorting).
''',
    keyPoints: [
      'Needs sorted input or a monotonic condition.',
      'Each step discards a pair that can never work.',
      'O(1) extra memory.',
    ],
    complexity: 'Time O(n) · Space O(1)',
    videoId: 'a9WHdJyos30',
    videoTitle: 'Two Sum II: sorted array two pointers, explained visually',
  ),
  Lesson(
    area: 'DSA',
    title: 'Sliding window',
    summary: 'Grow and shrink a contiguous range instead of recomputing it.',
    level: 'Intermediate',
    minutes: 20,
    question:
        'Given positive integers nums and a target, return the minimum length of a contiguous subarray whose sum is at least target, or 0 if none.',
    hints: [
      'A subarray is contiguous. Think of it as a window [left, right].',
      'Grow the window to the right until the sum reaches target.',
      'Then shrink from the left as long as the sum stays ≥ target, recording the best length.',
    ],
    notes: r'''
# The idea
Keep a running sum for the window. Moving the right edge adds one value; moving the left edge removes one. Each element enters and leaves once.

# Walkthrough: nums = [2, 3, 1, 2, 4, 3], target = 7
[array] 2,3,1,2,4,3 | 0:L,3:R | 0-3
1. Grow R until sum = 2+3+1+2 = 8 ≥ 7. Best length = 4.
[array] 2,3,1,2,4,3 | 3:L,5:R | 3-5
2. Keep sliding; window [2, 4, 3] reaches 9, then [4, 3] = 7. Best length = 2.

# Loop shape
[flow] Add nums[R] to sum -> While sum ≥ target: record length, subtract nums[L], L += 1 -> Move R forward

```
L = 0; total = 0; best = inf
for R, x in enumerate(nums):
    total += x
    while total >= target:
        best = min(best, R - L + 1)
        total -= nums[L]; L += 1
return 0 if best == inf else best
```

! This works because values are positive. With negatives, use prefix sums with a monotonic deque instead.
''',
    keyPoints: [
      'Window = contiguous range [L, R].',
      'Expand right, shrink left while the condition holds.',
      'Each index moves at most twice → linear time.',
    ],
    complexity: 'Time O(n) · Space O(1)',
    videoId: 'S6Xg-0uaODc',
    videoTitle: 'Minimum Size Subarray Sum: variable sliding window',
  ),
  Lesson(
    area: 'DSA',
    title: 'Binary search',
    summary: 'Halve the search space with every comparison.',
    level: 'Beginner',
    minutes: 15,
    question:
        'Given a sorted array of distinct integers and a target, return its index or -1. Explain why the loop is correct.',
    hints: [
      'If the target exists, where must it be relative to the middle element?',
      'Compare with the middle and throw away the half that cannot contain it.',
      'With a closed interval use while left <= right, then move to mid - 1 or mid + 1.',
    ],
    notes: r'''
# The idea
Sorted data lets you discard half the candidates after one comparison. 1,000,000 items need about 20 steps.

# Walkthrough: find 9 in [-1, 0, 3, 5, 9, 12]
[array] -1,0,3,5,9,12 | 0:lo,2:mid,5:hi | 0-5
1. mid = 2, value 3 < 9 → search right half.
[array] -1,0,3,5,9,12 | 3:lo,4:mid,5:hi | 3-5
2. mid = 4, value 9 = target → return 4.

# Invariant
> If the target exists, it is always inside [lo, hi]. Each loop makes the interval strictly smaller, so the loop ends.

```
lo, hi = 0, len(a) - 1
while lo <= hi:
    mid = lo + (hi - lo) // 2
    if a[mid] == target: return mid
    if a[mid] < target: lo = mid + 1
    else: hi = mid - 1
return -1
```

# Variants
- Lower bound: first index with a[i] ≥ target.
- Search on the answer: binary search any monotonic yes/no question.
- Rotated sorted arrays: decide which half is sorted first.
''',
    keyPoints: [
      'Requires order or a monotonic predicate.',
      'Use lo + (hi - lo) / 2 to avoid overflow.',
      'Keep the interval rules consistent to avoid off-by-one bugs.',
    ],
    complexity: 'Time O(log n) · Space O(1)',
    videoId: 'B7lMQIcIyN4',
    videoTitle: 'LeetCode 704 Binary Search: logic and code',
  ),
  Lesson(
    area: 'DSA',
    title: 'Stacks',
    summary: 'Last in, first out: perfect for nested structure.',
    level: 'Beginner',
    minutes: 15,
    question:
        'Given a string of brackets ()[]{}, decide whether every bracket is closed by the right type in the right order.',
    hints: [
      'A closing bracket must match the most recent unmatched opening one.',
      'Push opening brackets. On a closing bracket, check the top and pop.',
      'At the end the stack must be empty.',
    ],
    notes: r'''
# The idea
Nested things close in reverse order of opening. A stack gives you exactly the most recent unmatched item.

# Walkthrough: "{ [ ( ) ] }"
[stack] { [ (
1. Push {, [, ( as they appear. The top is (.
2. ")" matches the top ( → pop. "]" matches [ → pop. "}" matches { → pop.
3. Stack empty at the end → valid.

# Rules
[flow] Read character -> Opening? push it -> Closing? stack empty or top mismatched → invalid -> Otherwise pop -> End: valid only if stack is empty

```
pairs = {')': '(', ']': '[', '}': '{'}
stack = []
for ch in s:
    if ch in pairs:
        if not stack or stack.pop() != pairs[ch]:
            return False
    else:
        stack.append(ch)
return not stack
```

# Monotonic stack
Keep the stack sorted to answer "next greater element", daily temperatures and largest rectangle in a histogram in O(n).
''',
    keyPoints: [
      'Push and pop are O(1).',
      'Matches nesting: brackets, undo history, recursion.',
      'Monotonic stacks solve next-greater problems.',
    ],
    complexity: 'Time O(n) · Space O(n)',
    videoId: 'TaWs8tIrnoA',
    videoTitle: 'Valid Parentheses (LeetCode 20) with a stack',
  ),
  Lesson(
    area: 'DSA',
    title: 'Linked lists',
    summary: 'Rewire pointers carefully without losing the rest of the list.',
    level: 'Beginner',
    minutes: 15,
    question:
        'Reverse a singly linked list in place and return the new head.',
    hints: [
      'If you change cur.next first, you lose the rest of the list.',
      'Keep three references: prev, cur and the saved next.',
      'Loop until cur is null. The new head is prev.',
    ],
    notes: r'''
# The idea
Each node only knows the next node. To reverse, flip one arrow at a time while remembering where the rest of the list is.

# Before
[list] 1,2,3,4
# After
[list] 4,3,2,1

# One step
[flow] Save nxt = cur.next -> Point cur.next to prev -> Move prev = cur -> Move cur = nxt

```
prev, cur = None, head
while cur:
    nxt = cur.next
    cur.next = prev
    prev, cur = cur, nxt
return prev
```

# Related patterns
- Fast and slow pointers find the middle and detect cycles.
- A dummy head node removes special cases when inserting or deleting at the front.

! Test the empty list and a one-node list.
''',
    keyPoints: [
      'Always save next before rewiring.',
      'Index access is O(n); insert after a known node is O(1).',
      'Dummy nodes simplify edge cases.',
    ],
    complexity: 'Time O(n) · Space O(1)',
    videoId: '3butB3RvKcY',
    videoTitle: 'Reverse Linked List: iterative pointer reversal',
  ),
  Lesson(
    area: 'DSA',
    title: 'Trees: BFS level order',
    summary: 'Visit a tree level by level with a queue.',
    level: 'Intermediate',
    minutes: 20,
    question:
        'Given a binary tree, return its level-order traversal as a list of levels.',
    hints: [
      'Level order means visiting nodes by distance from the root.',
      'Use a FIFO queue, and read its size at the start of each level.',
      'Process exactly that many nodes, adding their children for the next level.',
    ],
    notes: r'''
# The tree
[tree] 3,9,20,null,null,15,7

# Expected output
[table] Level|Nodes ; 0|3 ; 1|9, 20 ; 2|15, 7

# How the queue moves
1. Queue = [3]. Size 1 → level [3]; enqueue 9, 20.
2. Queue = [9, 20]. Size 2 → level [9, 20]; enqueue 15, 7.
3. Queue = [15, 7]. Size 2 → level [15, 7].

```
res, q = [], deque([root]) if root else deque()
while q:
    level = []
    for _ in range(len(q)):
        node = q.popleft()
        level.append(node.val)
        if node.left: q.append(node.left)
        if node.right: q.append(node.right)
    res.append(level)
```

# DFS orders for comparison
[table] Order|Visit sequence|Example on this tree ; Preorder|node, left, right|3 9 20 15 7 ; Inorder|left, node, right|9 3 15 20 7 ; Postorder|left, right, node|9 15 7 20 3
''',
    keyPoints: [
      'BFS uses a queue; DFS uses recursion or a stack.',
      'Snapshot the queue size to separate levels.',
      'BFS space is the widest level.',
    ],
    complexity: 'Time O(n) · Space O(width)',
    videoId: '6ZnyEApgFYg',
    videoTitle: 'Binary Tree Level Order Traversal (NeetCode)',
  ),
  Lesson(
    area: 'DSA',
    title: 'Graphs: BFS and DFS',
    summary: 'Explore connected nodes without visiting any twice.',
    level: 'Intermediate',
    minutes: 20,
    question:
        'Given an undirected graph and a start vertex, list every vertex reachable from it. Compare BFS and DFS.',
    hints: [
      'Graphs can have cycles, so track visited vertices.',
      'BFS uses a queue; DFS uses recursion or a stack.',
      'Mark a vertex visited when you add it, not when you remove it.',
    ],
    notes: r'''
# The graph
[graph] A-B,A-C,B-D,C-D,D-E

# Adjacency list
[table] Vertex|Neighbours ; A|B, C ; B|A, D ; C|A, D ; D|B, C, E ; E|D

# Traversal order from A
[table] Method|Uses|Order ; BFS|queue|A, B, C, D, E ; DFS|stack / recursion|A, B, D, C, E

# BFS steps
[flow] Mark A, queue = [A] -> Pop vertex, visit it -> Push each unvisited neighbour and mark it -> Repeat until queue empty

```
visited = {start}; q = deque([start])
while q:
    v = q.popleft()
    for w in graph[v]:
        if w not in visited:
            visited.add(w); q.append(w)
```

> BFS finds shortest paths in unweighted graphs. DFS is the base for cycle detection, components and topological sort.

! Don't assume the graph is connected; loop over all vertices when counting components.
''',
    keyPoints: [
      'Adjacency list is the standard representation.',
      'Visited set prevents infinite loops.',
      'Both run in O(V + E).',
    ],
    complexity: 'Time O(V + E) · Space O(V)',
    videoId: 'D8ZS32wGs0s',
    videoTitle: 'BFS and DFS graph traversal algorithms explained',
  ),
  Lesson(
    area: 'DSA',
    title: 'Dynamic programming',
    summary: 'Store answers to subproblems instead of recomputing them.',
    level: 'Intermediate',
    minutes: 25,
    question:
        'You can climb 1 or 2 steps at a time. How many distinct ways reach step n? Turn the recursion into DP.',
    hints: [
      'To stand on step n, which step were you on just before?',
      'ways(n) = ways(n-1) + ways(n-2). Plain recursion repeats work.',
      'Build from the bottom up, keeping only the last two values.',
    ],
    notes: r'''
# The recurrence
You reach step n from step n-1 (one step) or n-2 (two steps), so ways(n) = ways(n-1) + ways(n-2).

# Recursion repeats work
[tree] 5,4,3,3,2,2,1

> Every repeated node above is wasted work. Memoization stores each answer once.

# Bottom-up table
[array] 1,1,2,3,5,8 | 0:n=0,5:n=5 | 5-5
[table] n|0|1|2|3|4|5 ; ways|1|1|2|3|5|8

# The DP recipe
1. Define the state: dp[i] = number of ways to reach step i.
2. Write the transition: dp[i] = dp[i-1] + dp[i-2].
3. Set the base cases: dp[0] = 1, dp[1] = 1.
4. Pick an order: top-down with memo, or bottom-up.
5. Reduce space: only two previous values are needed.

```
a, b = 1, 1
for _ in range(n - 1):
    a, b = b, a + b
return b
```

# Practise next
Coin change, house robber, 0/1 knapsack, longest common subsequence.
''',
    keyPoints: [
      'Overlapping subproblems + optimal substructure.',
      'State → transition → base case → order.',
      'Exponential recursion becomes linear.',
    ],
    complexity: 'Time O(n) · Space O(1) after rolling variables',
    videoId: 'Y0lT9Fck7qI',
    videoTitle: 'Climbing Stairs: Dynamic Programming (NeetCode)',
  ),
  Lesson(
    area: 'DSA',
    title: 'Backtracking',
    summary: 'Explore a decision tree: choose, explore, un-choose.',
    level: 'Intermediate',
    minutes: 25,
    question:
        'Generate all subsets of a list of distinct integers.',
    hints: [
      'Each element is either included or skipped.',
      'Add an element, recurse on the rest, then remove it.',
      'Save a copy of the current path, not a reference to it.',
    ],
    notes: r'''
# Decision tree for [1, 2]
[flow] [] -> include 1? -> [1] or [] -> include 2? -> [1,2], [1], [2], []

# All subsets of [1, 2, 3]
[table] Size|Subsets ; 0|[] ; 1|[1] [2] [3] ; 2|[1,2] [1,3] [2,3] ; 3|[1,2,3]

# Template
[flow] Record a copy of path -> For each remaining choice: add it -> Recurse -> Remove it (undo)

```
res, path = [], []
def dfs(start):
    res.append(path[:])
    for i in range(start, len(nums)):
        path.append(nums[i])
        dfs(i + 1)
        path.pop()
dfs(0)
```

> Pruning, meaning stopping a branch early when it cannot work, is what makes N-Queens and combination sum fast.

! With duplicate inputs, sort first and skip equal neighbours at the same depth.
''',
    keyPoints: [
      'Choose → explore → un-choose.',
      'There are 2ⁿ subsets.',
      'Prune branches that cannot succeed.',
    ],
    complexity: 'Time O(n · 2ⁿ) · Space O(n) recursion',
    videoId: 'REOH22Xwdkk',
    videoTitle: 'Subsets: Backtracking (NeetCode)',
  ),
  Lesson(
    area: 'DSA',
    title: 'Heaps and priority queues',
    summary: 'Always get the smallest (or largest) item fast.',
    level: 'Intermediate',
    minutes: 20,
    question:
        'Find the k-th largest element in an unsorted array. Compare sorting with a heap.',
    hints: [
      'Do you really need the whole array sorted?',
      'Keep a min-heap holding the k largest values seen so far.',
      'If the heap grows past k, pop the smallest. The root is the answer.',
    ],
    notes: r'''
# A min-heap
[tree] 1,3,2,7,4,5

> Every parent is ≤ its children, so the minimum is always at the root. It is stored as an array: children of index i are 2i+1 and 2i+2.

# Top-k with a heap of size k (k = 2)
[array] 3,2,1,5,6,4
[table] Read|Heap after|Action ; 3|[3]|push ; 2|[2,3]|push ; 1|[2,3]|push 1, size 3 > 2, pop 1 ; 5|[3,5]|pop 2 ; 6|[5,6]|pop 3 ; 4|[5,6]|pop 4

Answer: root = 5, the 2nd largest.

# Operations
[table] Operation|Cost ; peek|O(1) ; push|O(log n) ; pop|O(log n) ; build from array|O(n)

```
heap = []
for x in nums:
    heapq.heappush(heap, x)
    if len(heap) > k:
        heapq.heappop(heap)
return heap[0]
```

# Other uses
Merge k sorted lists, Dijkstra, task scheduling, running median with two heaps.
''',
    keyPoints: [
      'Min-heap of size k keeps the k largest.',
      'O(n log k) beats O(n log n) sorting.',
      'Quickselect averages O(n) but can degrade.',
    ],
    complexity: 'Time O(n log k) · Space O(k)',
    videoId: 'G7jGP6RC8sA',
    videoTitle: 'Kth Largest Element in an Array: min-heap solution',
  ),

  // ───────────────────────────── CTF ─────────────────────────────
  Lesson(
    area: 'CTF',
    title: 'Forensics: file signatures',
    summary: 'Identify a file by its bytes, not its name.',
    level: 'Beginner',
    minutes: 15,
    question:
        'A file has an unfamiliar extension and will not open. How do you find its real type, check for hidden data, and keep the evidence intact?',
    hints: [
      'Ignore the extension; look at the first bytes.',
      'Compare the header with known magic bytes using file and a hex viewer.',
      'Work on a copy, hash the original, and log every step.',
    ],
    notes: r'''
# Magic bytes
Most formats start with a fixed signature. The extension is just a label anyone can change.

[bytes] 89 50 4E 47 0D 0A 1A 0A | PNG image
[bytes] FF D8 FF | JPEG image
[bytes] 50 4B 03 04 | ZIP (also DOCX, APK, JAR)
[bytes] 25 50 44 46 | PDF document
[bytes] 7F 45 4C 46 | ELF Linux executable

# Workflow
[flow] Hash original (SHA-256) -> Copy and work on the copy -> file + xxd: read header and trailer -> Check structure, appended or embedded data -> Extract to a new folder, hash outputs -> Write up commands and findings

# Useful commands
```
sha256sum evidence.bin
file evidence.bin
xxd evidence.bin | head
binwalk evidence.bin
exiftool evidence.bin
```

> In CTFs, a "broken" image often just has a corrupted header. Fix the first bytes and it opens.

! Never modify the original evidence. Treat extracted files as untrusted.
''',
    keyPoints: [
      'Signatures beat extensions.',
      'Hash before and after every step.',
      'Check the end of the file for appended data.',
    ],
    complexity: 'Linear in file size. Provenance matters more than speed.',
    videoId: 'S-lQkprWKMw',
    videoTitle: 'File Signatures (Magic Bytes): fixing a broken file',
    exam: ['CEH v13 · Module 07: Malware Threats (file and static analysis)', 'CEH v13 · Module 01: Ethical hacking concepts (evidence handling)', 'CCSA · Threat Prevention: Threat Emulation and Threat Extraction (true file-type detection)'],
    practice: [PracticeLink('TryHackMe', 'File Carving', 'https://tryhackme.com/room/filecarving'), PracticeLink('HTB Academy', 'Introduction to Digital Forensics', 'https://academy.hackthebox.com/course/preview/introduction-to-digital-forensics'), PracticeLink('picoCTF', 'Forensics challenges', _pico + '4')],
  ),
  Lesson(
    area: 'CTF',
    title: 'Crypto: XOR',
    summary: 'Break single-byte XOR by trying all 256 keys.',
    level: 'Beginner',
    minutes: 20,
    question:
        'A ciphertext uses single-byte XOR. Describe how to recover the plaintext, and why repeating-key XOR is not secure.',
    hints: [
      'XORing with the same key twice gives back the original.',
      'There are only 256 possible one-byte keys. Try them all and score the output.',
      'For repeating keys, find the key length, then solve each column as single-byte XOR.',
    ],
    notes: r'''
# How XOR works
[table] A|B|A XOR B ; 0|0|0 ; 0|1|1 ; 1|0|1 ; 1|1|0

> C = P ⊕ K, and P = C ⊕ K, because K ⊕ K = 0.

# Example: 'H' with key 0x20
[bytes] 48 | 'H' plaintext
[bytes] 20 | key
[bytes] 68 | ciphertext 'h'

# Recovery workflow
[flow] Decode hex or Base64 into raw bytes -> Try all 256 keys -> Score each output (printable, spaces, letter frequency) -> Read the top candidates -> Confirm against the flag format

```
for k in range(256):
    out = bytes(b ^ k for b in data)
    score = sum(c in b' etaoinshr' for c in out)
```

# Repeating-key XOR
1. Guess the key length (Hamming distance between blocks).
2. Split bytes by key position into columns.
3. Solve each column as single-byte XOR.

! XOR alone is not encryption you should use. Use authenticated ciphers such as AES-GCM or ChaCha20-Poly1305.
''',
    keyPoints: [
      'XOR is its own inverse.',
      '256 keys is trivially brute-forced.',
      'Key reuse leaks patterns.',
    ],
    complexity: '256 × n byte operations, so O(n) for a fixed key space.',
    videoId: 'tE2iW_QAU1A',
    videoTitle: 'Cryptopals guided tour: single-byte XOR cipher',
    exam: ['CEH v13 · Module 20: Cryptography', 'CCSA · HTTPS Inspection and VPN encryption concepts'],
    practice: [PracticeLink('TryHackMe', 'Cryptography Basics', 'https://tryhackme.com/room/cryptographybasics'), PracticeLink('TryHackMe', 'Order (repeating-key XOR)', 'https://tryhackme.com/room/hfb1order'), PracticeLink('HTB', 'Crypto challenges', 'https://app.hackthebox.com/challenges'), PracticeLink('picoCTF', 'Cryptography challenges', _pico + '2')],
  ),
  Lesson(
    area: 'CTF',
    title: 'Network: PCAP triage',
    summary: 'Get the big picture before reading single packets.',
    level: 'Beginner',
    minutes: 20,
    question:
        'Given a PCAP from a simulated incident, outline how to find endpoints, protocols, suspicious conversations and a timeline.',
    hints: [
      'Start with capture properties and the protocol hierarchy.',
      'Use Conversations and Endpoints to see who talked to whom.',
      'Only then follow specific streams and build a timeline.',
    ],
    notes: r'''
# Top-down triage
[flow] Hash the capture -> Capture properties: duration, packets -> Statistics → Protocol Hierarchy -> Statistics → Conversations / Endpoints -> Filter and follow suspicious streams -> Timeline with packet numbers

# Handy display filters
[table] Goal|Filter ; DNS lookups|dns ; HTTP requests|http.request ; One host|ip.addr == 10.0.0.5 ; One TCP stream|tcp.stream eq 4 ; Failed TCP|tcp.flags.reset == 1

# What to look for
- Unusual ports or protocols for that network.
- Many DNS queries to random-looking domains.
- Large outbound transfers at odd hours.
- Plain-text credentials in HTTP, FTP or Telnet.

> Filters narrow what you see; they do not prove something is malicious. Confirm with logs.

! Do not open or run files extracted from the capture outside a sandbox.
''',
    keyPoints: [
      'Statistics first, packets later.',
      'Record packet numbers and timestamps.',
      'Separate facts from hypotheses.',
    ],
    complexity: 'Effort grows with capture size; filtering keeps it manageable.',
    videoId: 'ZNS115MPsO0',
    videoTitle: 'Reading PCAPs with Wireshark Statistics',
    exam: ['CEH v13 · Module 08: Sniffing', 'CEH v13 · Module 03: Scanning Networks (spotting scans in traffic)', 'CCSA · Logging and Monitoring (SmartConsole logs and traffic visibility)'],
    practice: [PracticeLink('TryHackMe', 'Wireshark: The Basics', 'https://tryhackme.com/room/wiresharkthebasics'), PracticeLink('HTB Academy', 'Intro to Network Traffic Analysis', 'https://academy.hackthebox.com/course/preview/intro-to-network-traffic-analysis'), PracticeLink('picoCTF', 'Forensics challenges (PCAPs)', _pico + '4')],
  ),
  Lesson(
    area: 'CTF',
    title: 'Web: reconnaissance and HTTP',
    summary: 'Map the application before testing anything.',
    level: 'Beginner',
    minutes: 20,
    question:
        'For an authorized web CTF target, plan low-impact reconnaissance that maps routes, technologies and inputs.',
    hints: [
      'Confirm the scope and request limits first.',
      'Browse normally through a proxy and record routes, forms and parameters.',
      'Check headers, cookies, robots.txt and JavaScript files for clues.',
    ],
    notes: r'''
# Recon loop
[flow] Confirm scope and rules -> Browse through Burp or ZAP -> Record routes, forms, parameters -> Inspect headers, cookies, JS files -> Rank hypotheses to test

# An HTTP request
```
GET /search?q=shoes HTTP/1.1
Host: shop.ctf.local
Cookie: session=abc123
User-Agent: Mozilla/5.0
```

# Where clues hide
[table] Place|What it can reveal ; Response headers|Server and framework versions ; robots.txt / sitemap|Hidden paths ; JavaScript bundles|API routes, feature flags ; Cookies|Session format, flags like HttpOnly ; Error pages|Stack traces, file paths

> Write down every input point. Your later tests come from this list.

! robots.txt is a hint, not permission. Stay inside the CTF scope and avoid noisy or destructive scans.
''',
    keyPoints: [
      'Scope first, always.',
      'Quality of notes beats scan volume.',
      'Every input is a test candidate.',
    ],
    complexity: 'Keep request volume low and bounded.',
    videoId: 'VGgQ4q7gfH4',
    videoTitle: 'Web app crawling with Burp Suite: recon and mapping',
    exam: ['CEH v13 · Module 02: Footprinting and Reconnaissance', 'CEH v13 · Module 14: Hacking Web Applications', 'CCSA · Threat Prevention: IPS and Application Control (detecting recon)'],
    practice: [PracticeLink('TryHackMe', 'Burp Suite: The Basics', 'https://tryhackme.com/room/burpsuitebasics'), PracticeLink('TryHackMe', 'Web Application Basics', 'https://tryhackme.com/room/webapplicationbasics'), PracticeLink('HTB Academy', 'Information Gathering - Web Edition', 'https://academy.hackthebox.com/course/preview/information-gathering---web-edition'), PracticeLink('picoCTF', 'Web Exploitation challenges', _pico + '1')],
  ),
  Lesson(
    area: 'CTF',
    title: 'Web: SQL injection',
    summary: 'When user input becomes part of the query.',
    level: 'Intermediate',
    minutes: 20,
    question:
        'A training app builds a SQL query by concatenating the username. Explain how to confirm SQL injection in a lab, the root cause, and the fix.',
    hints: [
      'Trace the input from the request into the query.',
      'In a lab, compare normal input with a quote or a boolean condition and watch the response.',
      'The fix is parameterized queries, not filtering characters.',
    ],
    notes: r'''
# Root cause
The query mixes code and data, so input can change the query's structure.

```
-- vulnerable
query = "SELECT * FROM users WHERE name = '" + name + "'"

-- input:  ' OR '1'='1
SELECT * FROM users WHERE name = '' OR '1'='1'
```

# Data flow
[flow] HTTP parameter -> String concatenation -> Database parses input as SQL -> Unintended rows returned

# Safe version
```
cursor.execute("SELECT * FROM users WHERE name = %s", (name,))
```

# Defence in depth
[table] Control|Why it helps ; Parameterized queries|Input can never become SQL ; Least-privilege DB user|Limits damage ; Generic error messages|Hides schema details ; Tests for each query|Stops regressions

> Input validation helps, but it does not replace parameterization.

! Only test intentionally vulnerable labs or CTF targets you are allowed to test.
''',
    keyPoints: [
      'Code and data must stay separate.',
      'Bound parameters fix the root cause.',
      'Least privilege limits impact.',
    ],
    complexity: 'Not an algorithm; judge exploitability and remediation.',
    videoId: 'wX6tszfgYp4',
    videoTitle: 'What is SQL injection? (PortSwigger Web Security Academy)',
    exam: ['CEH v13 · Module 15: SQL Injection', 'CEH v13 · Module 14: Hacking Web Applications', 'CCSA · Threat Prevention: IPS protections for web attacks'],
    practice: [PracticeLink('TryHackMe', 'SQL Injection', 'https://tryhackme.com/room/sqlinjectionlm'), PracticeLink('TryHackMe', 'SQL Injection Lab', 'https://tryhackme.com/room/sqlilab'), PracticeLink('HTB Academy', 'SQL Injection Fundamentals', 'https://academy.hackthebox.com/course/preview/sql-injection-fundamentals'), PracticeLink('picoCTF', 'Web Exploitation challenges', _pico + '1')],
  ),
  Lesson(
    area: 'CTF',
    title: 'Web: cross-site scripting (XSS)',
    summary: 'When a page runs text as script.',
    level: 'Intermediate',
    minutes: 20,
    question:
        'In an authorized training app, comments are shown on a page. How do you check whether output is encoded, why does XSS matter, and how do you fix it?',
    hints: [
      'Find where user input appears and in which context (HTML, attribute, JavaScript).',
      'Use a harmless marker in your lab and check whether it is encoded in the page source.',
      'Fix with context-aware output encoding and a strict Content-Security-Policy.',
    ],
    notes: r'''
# Three types
[table] Type|Where the payload lives ; Reflected|In the request, echoed back ; Stored|Saved on the server, shown to others ; DOM-based|Client JS writes it into the page

# How stored XSS flows
[flow] Attacker posts a comment -> Server saves it unchanged -> Victim opens the page -> Browser treats the text as script

# Encoding is the fix
```
<!-- unsafe: raw text inserted -->
<p>{{comment}}</p>      <!-- with escaping disabled -->

<!-- safe: special characters encoded -->
&lt;b&gt;hello&lt;/b&gt;
```

# Controls
- Escape output for its context (most template engines do this by default).
- Avoid dangerous sinks like innerHTML; use textContent.
- Sanitize rich text with a vetted library.
- Add a strict CSP and HttpOnly cookies.

! Only test applications you are authorized to test.
''',
    keyPoints: [
      'Context decides the encoding.',
      'Templates that escape by default prevent most XSS.',
      'CSP reduces impact.',
    ],
    complexity: 'Not an algorithm; evaluate exposure and remediation.',
    videoId: 'cbmBDiR6WaY',
    videoTitle: 'XSS: Cross Site Scripting explained',
    exam: ['CEH v13 · Module 14: Hacking Web Applications', 'CEH v13 · Module 11: Session Hijacking', 'CCSA · Threat Prevention: IPS web protections and HTTPS Inspection'],
    practice: [PracticeLink('TryHackMe', 'Intro to Cross-site Scripting', 'https://tryhackme.com/room/xss'), PracticeLink('HTB Academy', 'Cross-Site Scripting (XSS)', 'https://academy.hackthebox.com/course/preview/cross-site-scripting-xss'), PracticeLink('picoCTF', 'Web Exploitation challenges', _pico + '1')],
  ),
  Lesson(
    area: 'CTF',
    title: 'Linux permissions',
    summary: 'Read rwx, SUID and ownership like an auditor.',
    level: 'Intermediate',
    minutes: 20,
    question:
        'In a local privilege-escalation lab, a service has excessive permissions. How do you audit it and what do you fix?',
    hints: [
      'Start with who you are: id, groups, sudo -l.',
      'Look at SUID binaries, writable service files and capabilities.',
      'Fix with least privilege and correct ownership.',
    ],
    notes: r'''
# Reading a permission string
[perm] -rwsr-xr--

[table] Octal|Bits|Meaning ; 7|rwx|read, write, execute ; 5|r-x|read, execute ; 4|r--|read only ; 0|---|nothing

> The "s" in the owner slot is SUID: the program runs as its owner, often root. That is why SUID binaries matter.

# Audit flow
[flow] Identity: id, groups, sudo -l -> SUID/SGID: find / -perm -4000 -> Writable service files and folders -> systemd units and PATH -> Capabilities: getcap -r /

```
find / -perm -4000 -type f 2>/dev/null
getcap -r / 2>/dev/null
ls -l /etc/systemd/system/
```

# Fixes
- Run services as dedicated non-login accounts.
- Root-owned, non-writable service binaries and configs.
- Remove unnecessary SUID bits and capabilities.
- Use absolute paths in privileged scripts.

! Practise only on intentionally vulnerable VMs or CTF machines.
''',
    keyPoints: [
      'rwx for user, group, others.',
      'SUID runs as the file owner.',
      'Writable + privileged = escalation path.',
    ],
    complexity: 'Prioritize privileged assets; document scope.',
    videoId: 'uF1V8dNr06w',
    videoTitle: 'Linux SUID, SGID and Sticky Bit explained',
    exam: ['CEH v13 · Module 06: System Hacking (privilege escalation)', 'CEH v13 · Module 04: Enumeration', 'CCSA · Administrator roles, permissions and Gaia OS hardening (least privilege)'],
    practice: [PracticeLink('TryHackMe', 'Linux Privilege Escalation', 'https://tryhackme.com/room/linprivesc'), PracticeLink('TryHackMe', 'Common Linux Privesc', 'https://tryhackme.com/room/commonlinuxprivesc'), PracticeLink('HTB Academy', 'Linux Privilege Escalation', 'https://academy.hackthebox.com/course/preview/linux-privilege-escalation'), PracticeLink('picoCTF', 'General Skills challenges', _pico + '5')],
  ),
  Lesson(
    area: 'CTF',
    title: 'Reverse engineering basics',
    summary: 'Understand a program without its source.',
    level: 'Advanced',
    minutes: 30,
    question:
        'You have a small training binary that asks for a password. Describe a safe workflow to find what it checks.',
    hints: [
      'Use a disposable VM with snapshots.',
      'Start with strings, file type and imports.',
      'Read the check in a decompiler, then confirm in a debugger.',
    ],
    notes: r'''
# Workflow
[flow] Isolated VM + snapshot -> Triage: file, strings, hashes -> Open in Ghidra, find main -> Follow the input comparison -> Confirm in gdb -> Write the logic in plain words

# What decompiled code often looks like
```
int check(char *input) {
    for (int i = 0; i < 8; i++) {
        if ((input[i] ^ 0x13) != secret[i])
            return 0;
    }
    return 1;
}
```

> Here the password is secret[i] ^ 0x13 for each byte. Recognizing XOR loops and constant comparisons solves many beginner crackmes.

# Tools
[table] Stage|Tool ; Triage|file, strings, rabin2 ; Static|Ghidra, Cutter ; Dynamic|gdb + pwndbg, ltrace ; Patching|Ghidra, hex editor

! Only analyze CTF files or software you are allowed to analyze, and never on your main system.
''',
    keyPoints: [
      'Static first, dynamic to confirm.',
      'Rename variables as you understand them.',
      'Isolate unknown binaries.',
    ],
    complexity: 'Depends on obfuscation; good notes save hours.',
    videoId: 'fTGTnrgjuGA',
    videoTitle: 'Ghidra quickstart: solving a simple crackme',
    exam: ['CEH v13 · Module 07: Malware Threats (static and dynamic analysis)', 'CCSA · Threat Prevention: Threat Emulation (sandboxing unknown binaries)'],
    practice: [PracticeLink('TryHackMe', 'Red Queen Protocol (Ghidra, GDB)', 'https://tryhackme.com/room/redqueenprotocol'), PracticeLink('HTB Academy', 'Reverse Engineering 2', 'https://academy.hackthebox.com/course/preview/reverse-engineering-2'), PracticeLink('picoCTF', 'Reverse Engineering challenges', _pico + '3')],
  ),
];
