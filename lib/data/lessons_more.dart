// Extra DSA topics (completing the core syllabus) and the AI / ML / DL track.
import 'lessons.dart';

const _lc = 'https://leetcode.com/problems/';

const List<Lesson> extraDsaLessons = [
  Lesson(
    area: 'DSA',
    title: 'Big-O and complexity',
    summary: 'Measure how work grows as the input grows.',
    level: 'Beginner',
    minutes: 15,
    question: 'For each snippet, state the time complexity: a single loop over n, a loop nested inside another loop over n, and a loop that halves n each step.',
    hints: [
      'Count how many times the innermost line runs as n grows.',
      'Nested loops multiply: n times n.',
      'Halving each step means you reach 1 after about log₂ n steps.',
    ],
    notes: r'''
# Why it matters
Big-O describes how the running time or memory grows with input size n, ignoring constants. It tells you whether code will still be fast when n is a million.

# Common growth rates
[table] Big-O|Name|n = 1,000 → steps|Example ; O(1)|constant|1|array index ; O(log n)|logarithmic|~10|binary search ; O(n)|linear|1,000|one loop ; O(n log n)|linearithmic|~10,000|merge sort ; O(n²)|quadratic|1,000,000|nested loops ; O(2ⁿ)|exponential|astronomical|all subsets

# Rules of thumb
1. Drop constants: O(3n) is O(n).
2. Keep the biggest term: O(n² + n) is O(n²).
3. Sequential steps add; nested steps multiply.
4. Different inputs get different letters: O(n + m), not O(n).

```
for i in range(n):          # O(n)
    for j in range(n):      # × n → O(n²)
        work()

while n > 1:                # O(log n)
    n //= 2
```

> Interview limit check: about 10⁸ simple operations per second. n = 10⁵ rules out O(n²).
''',
    keyPoints: ['Count how work scales, not exact steps.', 'Drop constants and smaller terms.', 'Space complexity matters too.'],
    complexity: 'Answers: O(n) · O(n²) · O(log n)',
    videoId: 'v4cd1O4zkGw',
    videoTitle: 'Big O Notation · HackerRank (Gayle Laakmann McDowell)',
    practice: [PracticeLink('LeetCode', 'Contains Duplicate (compare O(n²) vs O(n))', '${_lc}contains-duplicate/')],
  ),
  Lesson(
    area: 'DSA',
    title: 'Prefix sums',
    summary: 'Precompute running totals to answer range sums in O(1).',
    level: 'Beginner',
    minutes: 15,
    question: 'Given an array and many queries (left, right), return the sum of elements between the two indices for each query, fast.',
    hints: [
      'Summing each range from scratch costs O(n) per query.',
      'Store the running total up to each index.',
      'sum(l..r) = prefix[r + 1] − prefix[l].',
    ],
    notes: r'''
# Build the prefix array
[array] 3,1,4,1,5
[array] 0,3,4,8,9,14 | 1:p[1],4:p[4]

prefix[i] holds the sum of the first i elements, so prefix[0] = 0.

# Answer a query: sum of indices 1..3
1. prefix[4] = 9 (sum of first 4 elements).
2. prefix[1] = 3 (sum of first 1 element).
3. 9 − 3 = 6, which is 1 + 4 + 1.

```
prefix = [0]
for x in nums:
    prefix.append(prefix[-1] + x)

def range_sum(l, r):
    return prefix[r + 1] - prefix[l]
```

# Related tricks
- Subarray sum equals k: count prefix sums in a hash map.
- 2D prefix sums for rectangle queries in a grid.
''',
    keyPoints: ['O(n) to build, O(1) per query.', 'Use one extra leading 0.', 'Combine with hash maps for "sum equals k".'],
    complexity: 'Build O(n) · Query O(1) · Space O(n)',
    videoId: 'bNvIQI2wAjk',
    videoTitle: 'Product of Array Except Self: prefix and postfix · NeetCode',
    practice: [
      PracticeLink('LeetCode', 'Range Sum Query - Immutable', '${_lc}range-sum-query-immutable/'),
      PracticeLink('LeetCode', 'Subarray Sum Equals K', '${_lc}subarray-sum-equals-k/'),
    ],
  ),
  Lesson(
    area: 'DSA',
    title: 'Recursion',
    summary: 'Solve a problem by solving a smaller copy of itself.',
    level: 'Beginner',
    minutes: 15,
    question: 'Write a recursive function for n! (factorial) and explain the base case and how the call stack unwinds.',
    hints: [
      'n! = n × (n − 1)!.',
      'Every recursion needs a stopping point: 0! = 1.',
      'Each call waits on the stack until the smaller call returns.',
    ],
    notes: r'''
# Two parts of every recursion
1. Base case: the smallest input you answer directly.
2. Recursive case: reduce the problem and call yourself.

```
def fact(n):
    if n == 0:        # base case
        return 1
    return n * fact(n - 1)
```

# The call stack for fact(3)
[stack] fact(0)=1 fact(1) fact(2) fact(3)

[flow] fact(3) waits for fact(2) -> fact(2) waits for fact(1) -> fact(1) waits for fact(0) -> fact(0) returns 1 -> Unwind: 1 → 1 → 2 → 6

! Missing or unreachable base case → stack overflow.

> Recursion is the foundation for trees, DFS, backtracking and divide-and-conquer.
''',
    keyPoints: ['Base case + smaller subproblem.', 'Each call uses stack memory.', 'Trust the recursive call to do its job.'],
    complexity: 'fact(n): Time O(n) · Space O(n) stack',
    videoId: 'IJDJ0kBx2LM',
    videoTitle: 'Recursion in Programming, full course · freeCodeCamp',
    practice: [PracticeLink('LeetCode', 'Fibonacci Number', '${_lc}fibonacci-number/'), PracticeLink('LeetCode', 'Pow(x, n)', '${_lc}powx-n/')],
  ),
  Lesson(
    area: 'DSA',
    title: 'Sorting: merge sort',
    summary: 'Divide, sort the halves, and merge them back.',
    level: 'Intermediate',
    minutes: 20,
    question: 'Sort an array using merge sort and explain why it runs in O(n log n).',
    hints: [
      'Split the array in half until each piece has one element.',
      'Merging two sorted lists takes linear time with two pointers.',
      'There are log n levels of splitting, each doing O(n) merge work.',
    ],
    notes: r'''
# Divide and conquer
[tree] 38·27·43·3,38·27,43·3,38,27,43,3

Split down to single elements, then merge pairs back in sorted order.

# Merging two sorted halves
[array] 27,38 | 0:i
[array] 3,43 | 0:j
Compare the fronts, take the smaller, move that pointer: 3, 27, 38, 43.

```
def merge_sort(a):
    if len(a) <= 1: return a
    mid = len(a) // 2
    L, R = merge_sort(a[:mid]), merge_sort(a[mid:])
    out, i, j = [], 0, 0
    while i < len(L) and j < len(R):
        if L[i] <= R[j]: out.append(L[i]); i += 1
        else: out.append(R[j]); j += 1
    return out + L[i:] + R[j:]
```

# Sorting algorithms compared
[table] Algorithm|Average|Worst|Extra space|Stable ; Merge sort|n log n|n log n|O(n)|yes ; Quick sort|n log n|n²|O(log n)|no ; Heap sort|n log n|n log n|O(1)|no ; Insertion sort|n²|n²|O(1)|yes
''',
    keyPoints: ['log n levels × O(n) merge = O(n log n).', 'Stable and predictable.', 'Needs O(n) extra space.'],
    complexity: 'Time O(n log n) · Space O(n)',
    videoId: 'mB5HXBb_HY8',
    videoTitle: 'Merge Sort algorithm · Abdul Bari',
    practice: [PracticeLink('LeetCode', 'Sort an Array', '${_lc}sort-an-array/'), PracticeLink('LeetCode', 'Merge Sorted Array', '${_lc}merge-sorted-array/')],
  ),
  Lesson(
    area: 'DSA',
    title: 'Queues and deques',
    summary: 'First in, first out; a deque works from both ends.',
    level: 'Intermediate',
    minutes: 20,
    question: 'Given an array and window size k, return the maximum of every window of size k.',
    hints: [
      'Recomputing the max of each window costs O(n·k).',
      'Keep a deque of indices whose values are in decreasing order.',
      'Pop from the back while the new value is bigger; pop from the front when the index leaves the window.',
    ],
    notes: r'''
# Queue vs deque
[table] Structure|Add|Remove|Use ; Queue|back|front|BFS, scheduling ; Deque|both ends|both ends|sliding window max, palindromes

# Walkthrough: [1, 3, -1, -3, 5], k = 3
[array] 1,3,-1,-3,5 | 0:L,2:R | 0-2
1. Deque after 3 elements holds indices of [3, -1] (1 was removed because 3 is bigger). Max = 3.
2. Add -3 → deque [3, -1, -3]. Max = 3.
3. Add 5 → pops everything smaller → [5]. Max = 5.

```
dq, out = deque(), []
for i, x in enumerate(nums):
    while dq and nums[dq[-1]] < x: dq.pop()
    dq.append(i)
    if dq[0] <= i - k: dq.popleft()
    if i >= k - 1: out.append(nums[dq[0]])
```

> The front of the deque is always the window maximum.
''',
    keyPoints: ['collections.deque gives O(1) at both ends.', 'Monotonic deque keeps useful candidates only.', 'Each index enters and leaves once.'],
    complexity: 'Time O(n) · Space O(k)',
    videoId: 'DfljaUwZsOk',
    videoTitle: 'Sliding Window Maximum: monotonic queue · NeetCode',
    practice: [PracticeLink('LeetCode', 'Sliding Window Maximum', '${_lc}sliding-window-maximum/'), PracticeLink('LeetCode', 'Implement Queue using Stacks', '${_lc}implement-queue-using-stacks/')],
  ),
  Lesson(
    area: 'DSA',
    title: 'Monotonic stack',
    summary: 'Find the next greater element for every item in one pass.',
    level: 'Intermediate',
    minutes: 20,
    question: 'Given daily temperatures, return for each day how many days you wait for a warmer one (0 if never).',
    hints: [
      'For each day you want the next greater value to the right.',
      'Keep a stack of indices still waiting for a warmer day.',
      'When today is warmer than the top, pop it and record the distance.',
    ],
    notes: r'''
# Walkthrough: [73, 74, 75, 71, 69, 72, 76]
[array] 73,74,75,71,69,72,76 | 3:wait,4:wait,5:today
1. 71 and 69 sit on the stack waiting.
2. 72 arrives: pops 69 (wait 1) and 71 (wait 2).
3. 76 arrives: pops 72 and 75.

[stack] 75 71 69

```
ans, st = [0] * len(t), []
for i, temp in enumerate(t):
    while st and t[st[-1]] < temp:
        j = st.pop()
        ans[j] = i - j
    st.append(i)
```

> The stack stays decreasing from bottom to top, which is why it is called monotonic.
''',
    keyPoints: ['Stack holds unresolved indices.', 'Each index pushed and popped once.', 'Same pattern: next greater element, histogram area.'],
    complexity: 'Time O(n) · Space O(n)',
    videoId: 'cTBiBSnjO3c',
    videoTitle: 'Daily Temperatures: monotonic stack · NeetCode',
    practice: [PracticeLink('LeetCode', 'Daily Temperatures', '${_lc}daily-temperatures/'), PracticeLink('LeetCode', 'Next Greater Element I', '${_lc}next-greater-element-i/')],
  ),
  Lesson(
    area: 'DSA',
    title: 'Binary search trees',
    summary: 'Left is smaller, right is bigger, at every node.',
    level: 'Intermediate',
    minutes: 20,
    question: 'Given a binary tree, decide whether it is a valid binary search tree.',
    hints: [
      'Comparing a node only with its children is not enough.',
      'Every node must fall inside a (low, high) range set by its ancestors.',
      'Going left tightens the upper bound; going right tightens the lower bound.',
    ],
    notes: r'''
# A valid BST
[tree] 8,3,10,1,6,null,14

[table] Operation|Balanced BST|Skewed BST ; search|O(log n)|O(n) ; insert|O(log n)|O(n) ; inorder traversal|sorted order|sorted order

# Range check
[flow] Start: 8 in (−∞, ∞) -> Go left: 3 in (−∞, 8) -> Go right of 3: 6 in (3, 8) -> Every node passes → valid

```
def valid(node, lo=float('-inf'), hi=float('inf')):
    if not node: return True
    if not (lo < node.val < hi): return False
    return valid(node.left, lo, node.val) and valid(node.right, node.val, hi)
```

> An inorder traversal of a BST is sorted. That alone is another valid check.
''',
    keyPoints: ['Pass bounds down the recursion.', 'Inorder = sorted.', 'Balance decides speed.'],
    complexity: 'Time O(n) · Space O(h)',
    videoId: 's6ATEkipzow',
    videoTitle: 'Validate Binary Search Tree · NeetCode',
    practice: [PracticeLink('LeetCode', 'Validate Binary Search Tree', '${_lc}validate-binary-search-tree/'), PracticeLink('LeetCode', 'Kth Smallest Element in a BST', '${_lc}kth-smallest-element-in-a-bst/')],
  ),
  Lesson(
    area: 'DSA',
    title: 'Tries (prefix trees)',
    summary: 'Store words letter by letter for fast prefix search.',
    level: 'Intermediate',
    minutes: 20,
    question: 'Implement a trie with insert(word), search(word) and startsWith(prefix).',
    hints: [
      'Each node holds a map from character to child node.',
      'Mark the node where a word ends.',
      'search needs the end mark; startsWith does not.',
    ],
    notes: r'''
# Words: car, cat, cut
[tree] root,c,null,a,u,null,null,r·t,null,t

Shared prefixes share nodes: "ca" is stored once for car and cat.

# Operations
[table] Operation|Cost|Needs end mark? ; insert(word)|O(L)|sets it ; search(word)|O(L)|yes ; startsWith(prefix)|O(L)|no

```
class Trie:
    def __init__(self):
        self.root = {}
    def insert(self, w):
        node = self.root
        for ch in w:
            node = node.setdefault(ch, {})
        node['$'] = True
    def search(self, w):
        node = self._walk(w)
        return node is not None and '$' in node
    def startsWith(self, p):
        return self._walk(p) is not None
    def _walk(self, s):
        node = self.root
        for ch in s:
            if ch not in node: return None
            node = node[ch]
        return node
```

> Used for autocomplete, spell check and word search puzzles.
''',
    keyPoints: ['Cost depends on word length, not word count.', 'End marker separates words from prefixes.', 'Great for autocomplete.'],
    complexity: 'Each operation O(L) for length L',
    videoId: 'oobqoCJlHA0',
    videoTitle: 'Implement Trie (Prefix Tree) · NeetCode',
    practice: [PracticeLink('LeetCode', 'Implement Trie (Prefix Tree)', '${_lc}implement-trie-prefix-tree/'), PracticeLink('LeetCode', 'Word Search II', '${_lc}word-search-ii/')],
  ),
  Lesson(
    area: 'DSA',
    title: 'Intervals',
    summary: 'Sort by start, then merge overlaps in one sweep.',
    level: 'Intermediate',
    minutes: 15,
    question: 'Given a list of intervals, merge all overlapping intervals.',
    hints: [
      'Sorting by start puts overlapping intervals next to each other.',
      'Compare each interval with the last merged one.',
      'They overlap if current.start ≤ last.end.',
    ],
    notes: r'''
# Example: [1,3] [2,6] [8,10] [15,18]
[table] Interval|Overlaps last?|Merged list ; [1,3]|–|[1,3] ; [2,6]|yes (2 ≤ 3)|[1,6] ; [8,10]|no|[1,6] [8,10] ; [15,18]|no|[1,6] [8,10] [15,18]

[flow] Sort by start -> For each interval -> Overlaps last merged? extend its end -> Otherwise append it

```
intervals.sort(key=lambda x: x[0])
merged = []
for s, e in intervals:
    if merged and s <= merged[-1][1]:
        merged[-1][1] = max(merged[-1][1], e)
    else:
        merged.append([s, e])
```

! Use max for the end: [1,10] then [2,3] must stay [1,10].
''',
    keyPoints: ['Sort first.', 'Compare with the last merged interval.', 'Take max of ends.'],
    complexity: 'Time O(n log n) · Space O(n)',
    videoId: '44H3cEC2fFM',
    videoTitle: 'Merge Intervals · NeetCode',
    practice: [PracticeLink('LeetCode', 'Merge Intervals', '${_lc}merge-intervals/'), PracticeLink('LeetCode', 'Insert Interval', '${_lc}insert-interval/')],
  ),
  Lesson(
    area: 'DSA',
    title: 'Greedy algorithms',
    summary: 'Make the best local choice and never look back.',
    level: 'Intermediate',
    minutes: 15,
    question: 'Each element is your maximum jump length from that index. Can you reach the last index?',
    hints: [
      'Work backwards: which index must you reach?',
      'Move the goal left whenever an index can jump to it.',
      'If the goal reaches index 0, the answer is yes.',
    ],
    notes: r'''
# Example: [2, 3, 1, 1, 4]
[array] 2,3,1,1,4 | 0:start,4:goal
1. Index 3 (jump 1) reaches 4 → goal = 3.
2. Index 2 (jump 1) reaches 3 → goal = 2.
3. Index 1 (jump 3) reaches 2 → goal = 1.
4. Index 0 (jump 2) reaches 1 → goal = 0 → true.

```
goal = len(nums) - 1
for i in range(len(nums) - 1, -1, -1):
    if i + nums[i] >= goal:
        goal = i
return goal == 0
```

# When greedy works
> Greedy is correct only if a local best choice never blocks the global best. If you can't argue that, use DP.

[table] Problem|Greedy works? ; Jump game|yes ; Coin change with any coins|no, use DP ; Interval scheduling by earliest end|yes
''',
    keyPoints: ['Prove the greedy choice is safe.', 'Often O(n) after sorting.', 'Fall back to DP when unsure.'],
    complexity: 'Time O(n) · Space O(1)',
    videoId: 'Yan0cv2cLy8',
    videoTitle: 'Jump Game: greedy · NeetCode',
    practice: [PracticeLink('LeetCode', 'Jump Game', '${_lc}jump-game/'), PracticeLink('LeetCode', 'Gas Station', '${_lc}gas-station/')],
  ),
  Lesson(
    area: 'DSA',
    title: 'Grid graphs',
    summary: 'Treat a 2D grid as a graph and flood-fill it.',
    level: 'Intermediate',
    minutes: 20,
    question: 'Given a grid of "1" (land) and "0" (water), count the islands.',
    hints: [
      'Each cell is a node; neighbours are up, down, left, right.',
      'When you find land, flood-fill the whole island.',
      'Mark visited cells so they are not counted again.',
    ],
    notes: r'''
# Example grid
[table] |c0|c1|c2|c3 ; r0|1|1|0|0 ; r1|1|0|0|1 ; r2|0|0|1|1

Two islands: the top-left group and the bottom-right group.

[flow] Scan every cell -> Found unvisited land? count += 1 -> DFS/BFS marks the whole island -> Continue scanning

```
def dfs(r, c):
    if r < 0 or c < 0 or r >= R or c >= C or grid[r][c] != '1':
        return
    grid[r][c] = '0'          # mark visited
    for dr, dc in ((1,0),(-1,0),(0,1),(0,-1)):
        dfs(r + dr, c + dc)
```

> BFS on a grid also gives shortest paths, e.g. rotting oranges or shortest path in a maze.
''',
    keyPoints: ['Cells are nodes, 4 directions are edges.', 'Mark visited in place or in a set.', 'Check bounds first.'],
    complexity: 'Time O(R·C) · Space O(R·C)',
    videoId: 'pV2kpPD66nE',
    videoTitle: 'Number of Islands · NeetCode',
    practice: [PracticeLink('LeetCode', 'Number of Islands', '${_lc}number-of-islands/'), PracticeLink('LeetCode', 'Rotting Oranges', '${_lc}rotting-oranges/')],
  ),
  Lesson(
    area: 'DSA',
    title: 'Topological sort',
    summary: 'Order tasks so every prerequisite comes first.',
    level: 'Advanced',
    minutes: 25,
    question: 'Given courses and prerequisite pairs, decide whether you can finish all courses, and give a valid order.',
    hints: [
      'Model prerequisites as directed edges.',
      'Start with courses that have no prerequisites (in-degree 0).',
      'If some courses never reach in-degree 0, there is a cycle.',
    ],
    notes: r'''
# Directed graph of prerequisites
[graph] A-B,A-C,B-D,C-D

Read as: A before B and C, both before D.

# Kahn's algorithm (BFS)
[table] Step|Queue|Order ; start|A|– ; take A|B, C|A ; take B|C|A, B ; take C|D|A, B, C ; take D|–|A, B, C, D

```
indeg = [0] * n
for a, b in edges: graph[a].append(b); indeg[b] += 1
q = deque(i for i in range(n) if indeg[i] == 0)
order = []
while q:
    v = q.popleft(); order.append(v)
    for w in graph[v]:
        indeg[w] -= 1
        if indeg[w] == 0: q.append(w)
return order if len(order) == n else []   # [] means a cycle
```

> Used for build systems, course planning and task schedulers.
''',
    keyPoints: ['Only works on DAGs.', 'In-degree 0 = ready to take.', 'Leftover nodes mean a cycle.'],
    complexity: 'Time O(V + E) · Space O(V + E)',
    videoId: 'WAOfKpxYHR8',
    videoTitle: 'Course Schedule I and II: topological sort · take U forward',
    practice: [PracticeLink('LeetCode', 'Course Schedule', '${_lc}course-schedule/'), PracticeLink('LeetCode', 'Course Schedule II', '${_lc}course-schedule-ii/')],
  ),
  Lesson(
    area: 'DSA',
    title: 'Union-find',
    summary: 'Track connected groups with near-constant merges.',
    level: 'Advanced',
    minutes: 20,
    question: 'Given n nodes and a list of edges, count the connected components using union-find.',
    hints: [
      'Each node starts as its own group, its own parent.',
      'find(x) follows parents to the root; union joins two roots.',
      'Every successful union reduces the component count by 1.',
    ],
    notes: r'''
# Parent pointers
[tree] 1,2,3,4

After union(1,2), union(1,3), union(2,4) everything shares root 1.

# Two optimisations
[table] Trick|What it does ; Path compression|find() points nodes straight at the root ; Union by rank/size|attach the smaller tree under the bigger

```
parent = list(range(n))
def find(x):
    while parent[x] != x:
        parent[x] = parent[parent[x]]   # path compression
        x = parent[x]
    return x
def union(a, b):
    ra, rb = find(a), find(b)
    if ra == rb: return False
    parent[ra] = rb
    return True
components = n - sum(union(a, b) for a, b in edges)
```

> Also detects cycles: a union that returns False means the edge closes a loop. Kruskal's MST uses this.
''',
    keyPoints: ['find + union, nearly O(1) each.', 'Detects cycles in undirected graphs.', 'Base of Kruskal\'s algorithm.'],
    complexity: 'Time O(α(n)) per operation, practically constant',
    videoId: 'ibjEGG7ylHk',
    videoTitle: 'Union Find introduction · WilliamFiset',
    practice: [PracticeLink('LeetCode', 'Number of Provinces', '${_lc}number-of-provinces/'), PracticeLink('LeetCode', 'Redundant Connection', '${_lc}redundant-connection/')],
  ),
  Lesson(
    area: 'DSA',
    title: 'Shortest paths: Dijkstra',
    summary: 'Always expand the closest unvisited node.',
    level: 'Advanced',
    minutes: 25,
    question: 'Given a weighted graph with non-negative edges and a source, find the shortest distance to every node.',
    hints: [
      'BFS is not enough when edges have different weights.',
      'Use a min-heap keyed by the current best distance.',
      'Skip heap entries that are older than the best known distance.',
    ],
    notes: r'''
# Weighted graph
[graph] S-A,S-B,A-B,A-C,B-C

Edge weights: S–A 4, S–B 1, B–A 2, A–C 1, B–C 5.

# Steps from S
[table] Pop|Distances after relaxing ; S (0)|A 4, B 1 ; B (1)|A 3 via B, C 6 ; A (3)|C 4 via A ; C (4)|done

```
dist = {s: 0}; heap = [(0, s)]
while heap:
    d, v = heapq.heappop(heap)
    if d > dist.get(v, inf): continue
    for w, cost in graph[v]:
        nd = d + cost
        if nd < dist.get(w, inf):
            dist[w] = nd
            heapq.heappush(heap, (nd, w))
```

! Negative edge weights break Dijkstra. Use Bellman-Ford instead.
''',
    keyPoints: ['Greedy with a min-heap.', 'Non-negative weights only.', 'Skip stale heap entries.'],
    complexity: 'Time O((V + E) log V) · Space O(V)',
    videoId: 'pSqmAO-m7Lk',
    videoTitle: 'Dijkstra\'s shortest path algorithm · WilliamFiset',
    practice: [PracticeLink('LeetCode', 'Network Delay Time', '${_lc}network-delay-time/'), PracticeLink('LeetCode', 'Path With Minimum Effort', '${_lc}path-with-minimum-effort/')],
  ),
  Lesson(
    area: 'DSA',
    title: '2D dynamic programming',
    summary: 'Fill a table where each cell depends on its neighbours.',
    level: 'Advanced',
    minutes: 25,
    question: 'Find the length of the longest common subsequence of two strings.',
    hints: [
      'Let dp[i][j] be the LCS of the first i letters of A and first j letters of B.',
      'If the letters match, extend the diagonal: dp[i-1][j-1] + 1.',
      'Otherwise take the best of skipping one letter: max(top, left).',
    ],
    notes: r'''
# Table for "ace" vs "abcde"
[table] |""|a|b|c|d|e ; ""|0|0|0|0|0|0 ; a|0|1|1|1|1|1 ; c|0|1|1|2|2|2 ; e|0|1|1|2|2|3

Answer is the bottom-right cell: 3 ("ace").

# Transition
[flow] Letters match? -> Yes: dp[i][j] = dp[i-1][j-1] + 1 -> No: dp[i][j] = max(dp[i-1][j], dp[i][j-1])

```
dp = [[0] * (n + 1) for _ in range(m + 1)]
for i in range(1, m + 1):
    for j in range(1, n + 1):
        if a[i-1] == b[j-1]:
            dp[i][j] = dp[i-1][j-1] + 1
        else:
            dp[i][j] = max(dp[i-1][j], dp[i][j-1])
```

> Same table shape: edit distance, 0/1 knapsack, unique paths in a grid.
''',
    keyPoints: ['State has two indices.', 'Extra row/column of zeros for empty prefixes.', 'Can reduce to two rows of memory.'],
    complexity: 'Time O(m·n) · Space O(m·n), or O(n) with rolling rows',
    videoId: 'Ua0GhsJSlWM',
    videoTitle: 'Longest Common Subsequence: 2D DP · NeetCode',
    practice: [PracticeLink('LeetCode', 'Longest Common Subsequence', '${_lc}longest-common-subsequence/'), PracticeLink('LeetCode', 'Edit Distance', '${_lc}edit-distance/'), PracticeLink('LeetCode', 'Unique Paths', '${_lc}unique-paths/')],
  ),
  Lesson(
    area: 'DSA',
    title: 'Bit manipulation',
    summary: 'Work directly with the 1s and 0s.',
    level: 'Intermediate',
    minutes: 15,
    question: 'Count the number of 1 bits in an unsigned integer.',
    hints: [
      'n & 1 tells you whether the lowest bit is 1.',
      'Shift right to look at the next bit.',
      'n & (n − 1) removes the lowest set bit, so loop until n is 0.',
    ],
    notes: r'''
# Operators
[table] Op|Meaning|5 (101) op 3 (011) ; AND|and (&)|001 = 1 ; OR|or|111 = 7 ; XOR|xor (^)|110 = 6 ; SHL|shift left (<<)|5 << 1 = 1010 = 10 ; SHR|shift right (>>)|5 >> 1 = 10 = 2

# Removing the lowest set bit
[bytes] 1 0 1 1 0 0 | n = 44
[bytes] 1 0 1 0 1 1 | n − 1 = 43
[bytes] 1 0 1 0 0 0 | n & (n − 1) = 40

```
count = 0
while n:
    n &= n - 1
    count += 1
```

# Handy tricks
- x & 1 → odd or even.
- x ^ x = 0 → find the single number among pairs.
- x & (x − 1) == 0 → x is a power of two (x > 0).
''',
    keyPoints: ['XOR cancels pairs.', 'n & (n−1) drops the lowest 1.', 'Shifts multiply or divide by 2.'],
    complexity: 'Time O(number of set bits) · Space O(1)',
    videoId: '5Km3utixwZs',
    videoTitle: 'Number of 1 Bits · NeetCode',
    practice: [PracticeLink('LeetCode', 'Number of 1 Bits', '${_lc}number-of-1-bits/'), PracticeLink('LeetCode', 'Single Number', '${_lc}single-number/')],
  ),
];

const _kaggle = 'https://www.kaggle.com/learn/';

const List<Lesson> aiLessons = [
  Lesson(
    area: 'AI',
    title: 'AI, ML and deep learning',
    summary: 'How the three terms fit inside each other.',
    level: 'Beginner',
    minutes: 10,
    question: 'Explain the difference between AI, machine learning and deep learning, with one real example of each.',
    hints: [
      'Think of three nested circles.',
      'ML learns rules from data instead of being hand-coded.',
      'Deep learning is ML with many-layered neural networks.',
    ],
    notes: r'''
# Nested fields
[flow] Artificial Intelligence: machines doing tasks that need intelligence -> Machine Learning: learning patterns from data -> Deep Learning: many-layer neural networks -> Generative AI / LLMs: models that create text, images, code

# Types of machine learning
[table] Type|Learns from|Example ; Supervised|labelled examples|spam vs not spam ; Unsupervised|unlabelled data|customer clusters ; Reinforcement|rewards from actions|game-playing agents

# The ML workflow
1. Collect and clean data.
2. Split into training and test sets.
3. Choose a model and train it.
4. Evaluate on unseen test data.
5. Deploy and monitor.

> In security: ML powers spam filters, malware classifiers and anomaly detection in network logs.
''',
    keyPoints: ['AI ⊃ ML ⊃ DL.', 'Supervised, unsupervised, reinforcement.', 'Always evaluate on unseen data.'],
    complexity: 'Concept lesson',
    videoId: 'q6kJ71tEYqM',
    videoTitle: 'Machine Learning vs Deep Learning · IBM Technology',
    practice: [PracticeLink('Kaggle', 'Intro to Machine Learning', '${_kaggle}intro-to-machine-learning')],
  ),
  Lesson(
    area: 'AI',
    title: 'Linear regression',
    summary: 'Fit the best straight line through data.',
    level: 'Beginner',
    minutes: 15,
    question: 'You have house sizes and prices. How does linear regression predict a price, and what does "best fit" mean?',
    hints: [
      'The model is a line: price = w × size + b.',
      'The error for one house is predicted minus actual.',
      'Best fit minimises the mean of squared errors.',
    ],
    notes: r'''
# The model
ŷ = w·x + b, where w is the slope (weight) and b is the intercept (bias).

# Example data
[table] Size (m²)|Price (lakh) ; 50|30 ; 80|48 ; 100|60 ; 120|72

Here w = 0.6 and b = 0, so a 90 m² house predicts 54 lakh.

# Loss: mean squared error
```
MSE = (1/n) × Σ (ŷᵢ − yᵢ)²
```

[flow] Guess w and b -> Predict ŷ for each point -> Measure MSE -> Adjust w, b to lower MSE -> Repeat until it stops improving

> R² tells you how much of the variation in y the line explains (1.0 is perfect).

! A straight line can't capture curved relationships. Add features or use another model.
''',
    keyPoints: ['ŷ = wx + b.', 'Minimise mean squared error.', 'R² measures fit quality.'],
    complexity: 'Training O(n·d) per pass for n samples, d features',
    videoId: 'nk2CQITm_eo',
    videoTitle: 'Linear Regression, clearly explained · StatQuest',
    practice: [PracticeLink('Kaggle', 'Intro to Machine Learning', '${_kaggle}intro-to-machine-learning')],
  ),
  Lesson(
    area: 'AI',
    title: 'Gradient descent',
    summary: 'Walk downhill on the loss to find good weights.',
    level: 'Beginner',
    minutes: 20,
    question: 'Explain how gradient descent updates a weight, and what happens if the learning rate is too big or too small.',
    hints: [
      'The gradient points uphill on the loss surface.',
      'Step in the opposite direction: w = w − lr × gradient.',
      'Too big overshoots; too small crawls.',
    ],
    notes: r'''
# The update rule
```
w = w − learning_rate × ∂Loss/∂w
```

[flow] Start with random weights -> Compute loss on a batch -> Compute gradient of loss -> Step opposite the gradient -> Repeat for many epochs

# Learning rate
[table] Learning rate|Behaviour ; too small|very slow, may stall ; just right|steady decrease in loss ; too large|bounces around or diverges

# Variants
[table] Variant|Uses per step ; Batch GD|all data ; Stochastic GD|one example ; Mini-batch GD|a small batch (most common) ; Adam|mini-batch + adaptive step sizes

> Every neural network you have heard of is trained with some version of this loop.
''',
    keyPoints: ['Move against the gradient.', 'Learning rate controls step size.', 'Mini-batches balance speed and stability.'],
    complexity: 'One step costs one forward + backward pass over a batch',
    videoId: 'IHZwWFHWa-w',
    videoTitle: 'Gradient descent, how neural networks learn · 3Blue1Brown',
    practice: [PracticeLink('Kaggle', 'Intro to Deep Learning', '${_kaggle}intro-to-deep-learning')],
  ),
  Lesson(
    area: 'AI',
    title: 'Logistic regression',
    summary: 'Turn a score into a probability for yes/no decisions.',
    level: 'Beginner',
    minutes: 15,
    question: 'How does logistic regression decide whether an email is spam, and why not use plain linear regression?',
    hints: [
      'Linear regression can output values below 0 or above 1.',
      'The sigmoid squashes any number into (0, 1).',
      'Pick a threshold, often 0.5, to decide the class.',
    ],
    notes: r'''
# From score to probability
```
z = w·x + b
p = sigmoid(z) = 1 / (1 + e^(−z))
```

[table] z|sigmoid(z) ; −4|0.02 ; 0|0.50 ; 2|0.88 ; 4|0.98

[flow] Features (links, words, sender) -> Weighted sum z -> Sigmoid → probability -> p ≥ 0.5 → spam, else not spam

# Loss: log loss (cross-entropy)
Confident wrong answers are punished heavily, which pushes the model to be well calibrated.

> Despite the name, logistic regression is a classification model.
''',
    keyPoints: ['Sigmoid maps to (0, 1).', 'Threshold turns probability into a class.', 'Trained with cross-entropy loss.'],
    complexity: 'Same training cost as linear regression',
    videoId: 'yIYKR4sgzI8',
    videoTitle: 'Logistic Regression · StatQuest',
    practice: [PracticeLink('Kaggle', 'Intro to Machine Learning', '${_kaggle}intro-to-machine-learning')],
  ),
  Lesson(
    area: 'AI',
    title: 'Evaluating models',
    summary: 'Overfitting, bias vs variance, and the right metric.',
    level: 'Intermediate',
    minutes: 20,
    question: 'A model scores 99% on training data but 70% on test data. What is happening and how would you fix it?',
    hints: [
      'Compare training and test performance.',
      'A big gap means the model memorised the training set.',
      'Simplify the model, add data, or regularise.',
    ],
    notes: r'''
# Bias vs variance
[table] Problem|Train score|Test score|Fix ; Underfitting (high bias)|low|low|bigger model, better features ; Good fit|high|high|ship it ; Overfitting (high variance)|very high|much lower|more data, regularisation, simpler model

# Data splits
[flow] Full dataset -> Training set (fit the model) -> Validation set (tune settings) -> Test set (final, touch once)

# Confusion matrix for a malware detector
[table] |Predicted malware|Predicted clean ; Actually malware|TP|FN (missed!) ; Actually clean|FP (false alarm)|TN

# Metrics
- Accuracy = (TP + TN) / all. Misleading when classes are imbalanced.
- Precision = TP / (TP + FP): of the alarms, how many were real?
- Recall = TP / (TP + FN): of the real threats, how many did we catch?
- F1 = harmonic mean of precision and recall.

! With 1% malware, a model that always says "clean" is 99% accurate and useless.
''',
    keyPoints: ['Never evaluate on training data.', 'Watch the train–test gap.', 'Pick precision/recall to match the cost of mistakes.'],
    complexity: 'Concept lesson',
    videoId: 'EuBBz3bI-aA',
    videoTitle: 'Machine learning fundamentals: bias and variance · StatQuest',
    practice: [PracticeLink('Kaggle', 'Intermediate Machine Learning', '${_kaggle}intermediate-machine-learning')],
  ),
  Lesson(
    area: 'AI',
    title: 'Decision trees and forests',
    summary: 'Ask yes/no questions; many trees vote better than one.',
    level: 'Intermediate',
    minutes: 20,
    question: 'How does a decision tree choose its first question, and why does a random forest usually beat a single tree?',
    hints: [
      'Each split should make the groups purer.',
      'Measure purity with Gini impurity or entropy.',
      'A forest averages many different trees, reducing variance.',
    ],
    notes: r'''
# A tiny phishing-URL tree
[tree] Has IP?,Phishing,Many dots?,null,null,Phishing,Safe

Each node asks a question; leaves give the prediction.

# Choosing splits
[flow] Try every feature and threshold -> Measure impurity of the two groups -> Keep the split with the biggest drop -> Repeat on each child until stopping

# Single tree vs forest
[table] |Decision tree|Random forest ; Interpretability|high|lower ; Overfitting risk|high|low ; Training|fast|slower (many trees) ; Accuracy|good|usually better

> Random forest = many trees, each trained on a random sample of rows and features, then they vote.
''',
    keyPoints: ['Splits maximise purity.', 'Deep trees overfit.', 'Forests reduce variance by voting.'],
    complexity: 'Tree training about O(n·d·log n)',
    videoId: '_L39rN6gz7Y',
    videoTitle: 'Decision and classification trees · StatQuest',
    practice: [PracticeLink('Kaggle', 'Intro to Machine Learning', '${_kaggle}intro-to-machine-learning')],
  ),
  Lesson(
    area: 'AI',
    title: 'K-means clustering',
    summary: 'Group unlabelled data around k centres.',
    level: 'Intermediate',
    minutes: 15,
    question: 'Describe the k-means algorithm and how to choose k.',
    hints: [
      'Start with k random centres.',
      'Assign each point to the nearest centre, then move centres to the mean.',
      'Plot error against k and look for the elbow.',
    ],
    notes: r'''
# The loop
[flow] Pick k random centroids -> Assign each point to nearest centroid -> Move each centroid to the mean of its points -> Repeat until assignments stop changing

# Example: login times, k = 2
[table] Point|Hour|Cluster ; 1|9|day ; 2|10|day ; 3|11|day ; 4|2|night ; 5|3|night

> The "night" cluster could flag unusual access patterns, which is anomaly detection without labels.

# Choosing k
- Elbow method: plot within-cluster error vs k and pick the bend.
- Silhouette score: higher means better-separated clusters.

! K-means assumes round, similar-size clusters and is sensitive to feature scale. Standardise first.
''',
    keyPoints: ['Unsupervised: no labels needed.', 'Assign → update, repeat.', 'Scale features; pick k with elbow or silhouette.'],
    complexity: 'O(n·k·iterations) per run',
    videoId: '4b5d3muPQmA',
    videoTitle: 'K-means clustering · StatQuest',
    practice: [PracticeLink('Kaggle', 'Feature Engineering (clustering lesson)', '${_kaggle}feature-engineering')],
  ),
  Lesson(
    area: 'AI',
    title: 'Neural networks',
    summary: 'Layers of simple units that learn features.',
    level: 'Intermediate',
    minutes: 20,
    question: 'What does a single neuron compute, and why do networks need activation functions?',
    hints: [
      'A neuron computes a weighted sum plus a bias.',
      'Without a non-linear activation, stacked layers collapse to one linear layer.',
      'ReLU(x) = max(0, x) is the common choice.',
    ],
    notes: r'''
# One neuron
```
output = activation(w₁x₁ + w₂x₂ + … + b)
```

# A small network
[flow] Input layer: 784 pixels -> Hidden layer: 16 neurons (ReLU) -> Hidden layer: 16 neurons (ReLU) -> Output: 10 digits (softmax)

# Activation functions
[table] Function|Output range|Used for ; ReLU|0 to ∞|hidden layers ; Sigmoid|0 to 1|binary output ; Softmax|probabilities summing to 1|multi-class output ; Tanh|−1 to 1|older RNNs

> Each layer learns features of the previous one: edges → shapes → digits.

! More layers and neurons mean more capacity, but also more data and compute, and more risk of overfitting.
''',
    keyPoints: ['Weighted sum + bias + activation.', 'Non-linearity is essential.', 'Softmax for multi-class outputs.'],
    complexity: 'Forward pass cost ≈ number of weights',
    videoId: 'aircAruvnKk',
    videoTitle: 'But what is a neural network? · 3Blue1Brown',
    practice: [PracticeLink('Kaggle', 'Intro to Deep Learning', '${_kaggle}intro-to-deep-learning')],
  ),
  Lesson(
    area: 'AI',
    title: 'Backpropagation',
    summary: 'Send the error backwards to find every weight\'s blame.',
    level: 'Advanced',
    minutes: 20,
    question: 'Explain in plain words what backpropagation computes and how it connects to gradient descent.',
    hints: [
      'Gradient descent needs ∂Loss/∂w for every weight.',
      'The chain rule lets you compute these layer by layer from the output backwards.',
      'Each weight changes in proportion to how much it contributed to the error.',
    ],
    notes: r'''
# One training step
[flow] Forward pass: compute predictions -> Compute loss vs the true label -> Backward pass: chain rule from output to input -> Update every weight with gradient descent

# The chain rule
```
∂L/∂w = ∂L/∂ŷ × ∂ŷ/∂z × ∂z/∂w
```
Each factor is cheap and local, so one backward pass gives all gradients.

# Common training problems
[table] Problem|Symptom|Typical fix ; Vanishing gradients|early layers stop learning|ReLU, residual connections ; Exploding gradients|loss becomes NaN|gradient clipping, lower LR ; Overfitting|train ≫ test|dropout, more data

> Frameworks such as PyTorch do this automatically (autograd), but knowing it helps you debug training.
''',
    keyPoints: ['Chain rule, applied backwards.', 'One backward pass gives all gradients.', 'Feeds gradient descent.'],
    complexity: 'Backward pass ≈ 2× the forward pass cost',
    videoId: 'Ilg3gGewQ5U',
    videoTitle: 'Backpropagation, intuitively · 3Blue1Brown',
    practice: [PracticeLink('Kaggle', 'Intro to Deep Learning', '${_kaggle}intro-to-deep-learning')],
  ),
  Lesson(
    area: 'AI',
    title: 'Convolutional networks (CNNs)',
    summary: 'Slide small filters over images to detect patterns.',
    level: 'Advanced',
    minutes: 20,
    question: 'Why do CNNs work better than plain dense networks for images?',
    hints: [
      'A dense layer connects every pixel to every neuron, which means huge numbers of weights.',
      'A filter reuses the same small set of weights across the whole image.',
      'Pooling shrinks the image while keeping the strongest signals.',
    ],
    notes: r'''
# Pipeline
[flow] Image -> Convolution (filters detect edges) -> ReLU -> Pooling (downsample) -> More conv + pool (shapes, objects) -> Flatten -> Dense layer -> Class probabilities

# A 3×3 edge filter
[table] -1|0|1 ; -1|0|1 ; -1|0|1

Sliding it over the image lights up vertical edges.

# Key terms
[table] Term|Meaning ; Kernel/filter|small weight grid, e.g. 3×3 ; Stride|how far the filter moves each step ; Padding|zeros added around the border ; Pooling|take max/average of a small region

> In security: CNNs classify malware by turning binaries into images, and read CAPTCHAs.
''',
    keyPoints: ['Shared filter weights → far fewer parameters.', 'Early layers see edges, later layers see objects.', 'Pooling reduces size.'],
    complexity: 'Cost ≈ image size × filter size × number of filters',
    videoId: 'HGwBXDKFk9I',
    videoTitle: 'Image classification with CNNs · StatQuest',
    practice: [PracticeLink('Kaggle', 'Computer Vision', '${_kaggle}computer-vision')],
  ),
  Lesson(
    area: 'AI',
    title: 'Transformers and LLMs',
    summary: 'Attention lets every word look at every other word.',
    level: 'Advanced',
    minutes: 25,
    question: 'At a high level, how does a model like GPT generate text, and what does attention do?',
    hints: [
      'Text is split into tokens and each token becomes a vector.',
      'Attention lets each token gather information from the other tokens.',
      'The model predicts the next token, appends it, and repeats.',
    ],
    notes: r'''
# Generation loop
[flow] Text → tokens -> Tokens → embedding vectors -> Transformer blocks: attention + feed-forward -> Probabilities for the next token -> Sample a token, append, repeat

# Attention in one line
Each token asks "which other tokens matter to me?" (query), compares with every token's key, and mixes their values by those scores.

```
Attention(Q, K, V) = softmax(Q·Kᵀ / √d) · V
```

# Model families
[table] Model type|Example|Good at ; Encoder|BERT|understanding, classification ; Decoder|GPT, Claude|generating text ; Encoder–decoder|T5|translation, summarisation

! LLMs can state wrong facts confidently and are vulnerable to prompt injection. Verify outputs and never trust untrusted input as instructions.
''',
    keyPoints: ['Next-token prediction, repeated.', 'Attention mixes information across tokens.', 'Verify outputs; beware prompt injection.'],
    complexity: 'Attention costs O(n²) in sequence length',
    videoId: 'wjZofJX0v4M',
    videoTitle: 'Transformers, the tech behind LLMs · 3Blue1Brown',
    practice: [PracticeLink('Kaggle', 'Intro to Deep Learning', '${_kaggle}intro-to-deep-learning')],
  ),
];

const _pico = 'https://play.picoctf.org/practice?category=';

const List<Lesson> ctfExtraLessons = [
  Lesson(
    area: 'CTF',
    title: 'Binary exploitation basics',
    summary: 'How a buffer overflow takes over a program.',
    level: 'Advanced',
    minutes: 30,
    question: 'A training binary copies your input into a 64-byte buffer with gets(). Explain why that is dangerous, how an overflow can change control flow, and which protections stop it.',
    hints: [
      'gets() never checks the length of the input.',
      'Past the buffer on the stack sit the saved frame pointer and the return address.',
      'Canaries, NX and ASLR each block a different step of the attack.',
    ],
    notes: r'''
# The stack frame
[stack] return-address saved-RBP buffer[64]

Writing more than 64 bytes runs past the buffer, over the saved frame pointer, and into the return address. When the function returns, the CPU jumps wherever that address points.

# Attack steps (in a lab)
[flow] Find the input that crashes the program -> Find the offset to the return address (cyclic pattern) -> Overwrite it with a target address -> Program jumps to attacker-chosen code

# Protections
[table] Protection|What it stops ; Stack canary|detects the overwrite before returning ; NX / DEP|stack memory can't execute code ; ASLR / PIE|addresses change every run ; RELRO|protects the GOT from overwrites

```
checksec ./vuln          # which protections are on
gdb ./vuln               # find the crash and offset
python3 -c "from pwn import *; print(cyclic(100))"
```

> The fix is in the code: use fgets(buf, sizeof buf, stdin), bounds checks, and memory-safe languages.

! Only exploit binaries from CTFs or labs you are allowed to attack.
''',
    keyPoints: ['Unchecked copies overwrite the return address.', 'Find the offset, then control the jump.', 'Canary, NX, ASLR each block a step.'],
    complexity: 'Effort grows with each protection you must bypass',
    videoId: 'wa3sMSdLyHw',
    videoTitle: 'Intro to binary exploitation: buffer overflows · CryptoCat',
    exam: ['CEH v13 · Module 06: System Hacking (buffer overflows)', 'CEH v13 · Module 05: Vulnerability Analysis', 'CCSA · Threat Prevention: IPS protections against exploit traffic'],
    practice: [
      PracticeLink('TryHackMe', 'Intro To Pwntools', 'https://tryhackme.com/room/introtopwntools'),
      PracticeLink('HTB Academy', 'Stack-Based Buffer Overflows on Linux x86', 'https://academy.hackthebox.com/course/preview/stack-based-buffer-overflows-on-linux-x86'),
      PracticeLink('picoCTF', 'Binary Exploitation challenges', '${_pico}6'),
    ],
  ),
  Lesson(
    area: 'CTF',
    title: 'OSINT investigations',
    summary: 'Find answers in public information, methodically.',
    level: 'Beginner',
    minutes: 20,
    question: 'A CTF gives you one photo and a username. Describe a methodical OSINT process to find where the photo was taken and which accounts belong to the user.',
    hints: [
      'Start with what the file itself contains: metadata.',
      'Reverse image search and landmarks can geolocate a photo.',
      'Check the username across platforms, then confirm links with more than one clue.',
    ],
    notes: r'''
# OSINT cycle
[flow] Define the question -> Collect from public sources -> Pivot on each new clue -> Verify with two or more sources -> Report with evidence

# Pivots from one clue
[table] Starting point|Next step|Tool ; Image|metadata, GPS, reverse search|exiftool, Google Lens, Yandex ; Username|same name on other sites|Sherlock, WhatsMyName ; Email|breaches, registered accounts|Have I Been Pwned ; Domain|WHOIS, DNS, old versions|whois, crt.sh, Wayback Machine

# Good habits
- Screenshot and note the URL and time of every finding.
- One matching username is a weak signal; matching photo, writing style and location is strong.
- Separate facts from guesses in your notes.

! OSINT is for CTF targets and authorised work only. Never use it to stalk or expose real people.
''',
    keyPoints: ['Pivot from clue to clue.', 'Verify with independent sources.', 'Document every step.'],
    complexity: 'Investigation time depends on how many pivots you need',
    videoId: 'qwA6MmbeGNo',
    videoTitle: 'Open-Source Intelligence (OSINT) full course · The Cyber Mentor',
    exam: ['CEH v13 · Module 02: Footprinting and Reconnaissance', 'CEH v13 · Module 09: Social Engineering'],
    practice: [
      PracticeLink('TryHackMe', 'OhSINT', 'https://tryhackme.com/room/ohsint'),
      PracticeLink('TryHackMe', 'Sakura Room', 'https://tryhackme.com/room/sakura'),
      PracticeLink('HTB Academy', 'OSINT: Corporate Recon', 'https://academy.hackthebox.com/course/preview/osint-corporate-recon'),
    ],
  ),
  Lesson(
    area: 'CTF',
    title: 'Steganography',
    summary: 'Find data hidden inside images and audio.',
    level: 'Beginner',
    minutes: 20,
    question: 'You get a normal-looking PNG and a WAV file. Describe the checks you would run, in order, to find a hidden flag.',
    hints: [
      'Start cheap: file type, strings and metadata.',
      'Check for files appended or embedded inside.',
      'Then try pixel tricks (least significant bits) and audio spectrograms.',
    ],
    notes: r'''
# How LSB hiding works
[bytes] 1 0 1 1 0 1 1 0 | pixel byte, last bit replaced
Changing the least significant bit of each colour value barely changes the picture, but 8 pixels carry one hidden byte.

# Checklist
[flow] file + strings -> exiftool (metadata, comments) -> binwalk (embedded files) -> zsteg / stegsolve (PNG bit planes) -> steghide (JPEG, password) -> Audacity / Sonic Visualiser (spectrogram)

# Tools by format
[table] Format|Try first ; PNG / BMP|zsteg, stegsolve ; JPEG|steghide, stegseek, exiftool ; WAV / MP3|spectrogram view, strings ; Any|binwalk, strings, hex editor

> Most CTF stego is solved by the first three cheap checks. Don't jump to brute force.
''',
    keyPoints: ['Cheap checks first.', 'LSB = tiny change, hidden bits.', 'Spectrograms reveal audio messages.'],
    complexity: 'Mostly quick checks; password brute force is slow',
    videoId: 'TWEXCYQKyDc',
    videoTitle: 'Secrets hidden in images (steganography) · Computerphile',
    exam: ['CEH v13 · Module 06: System Hacking (steganography)', 'CCSA · Threat Prevention: Threat Extraction (removing hidden content)'],
    practice: [
      PracticeLink('TryHackMe', 'c4ptur3-th3-fl4g', 'https://tryhackme.com/room/c4ptur3th3fl4g'),
      PracticeLink('TryHackMe', 'Cicada-3301 Vol:1', 'https://tryhackme.com/room/cicada3301vol1'),
      PracticeLink('picoCTF', 'Forensics challenges', '${_pico}4'),
    ],
  ),
  Lesson(
    area: 'CTF',
    title: 'Active Directory basics',
    summary: 'How Windows domains work, and where attacks start.',
    level: 'Advanced',
    minutes: 25,
    question: 'Explain what a domain controller does, how Kerberos logs a user in, and why a weak service account password is dangerous.',
    hints: [
      'The domain controller stores accounts and checks logins for the whole network.',
      'Kerberos gives you tickets instead of sending your password around.',
      'Service tickets are encrypted with the service account password, so they can be cracked offline.',
    ],
    notes: r'''
# Structure
[flow] Forest -> Domain (corp.local) -> Organisational Units -> Users, groups, computers

# Kerberos login
[flow] User asks the KDC for a TGT -> KDC checks the password, returns the TGT -> User asks for a service ticket with the TGT -> User presents the ticket to the service

# Common attacks and defences
[table] Attack|Abuses|Defence ; Password spraying|weak common passwords|lockout policy, MFA ; Kerberoasting|weak service account passwords|long random passwords, gMSA ; AS-REP roasting|accounts without pre-auth|require pre-auth ; Pass-the-hash|NTLM hash reuse|LAPS, disable NTLM

> BloodHound maps relationships between users, groups and computers to show the shortest path to Domain Admin.

! Practise only in labs like TryHackMe or HTB Academy, never on a real company network without written permission.
''',
    keyPoints: ['DC = central identity and login.', 'Kerberos uses tickets, not passwords.', 'Weak service passwords enable Kerberoasting.'],
    complexity: 'Large domains mean many paths; tools map them',
    videoId: 'VLWt0-8BOV4',
    videoTitle: 'Active Directory · Professor Messer',
    exam: ['CEH v13 · Module 04: Enumeration (LDAP, Kerberos)', 'CEH v13 · Module 06: System Hacking (password attacks)', 'CCSA · Identity Awareness (AD integration and user-based policies)'],
    practice: [
      PracticeLink('TryHackMe', 'Active Directory Basics', 'https://tryhackme.com/room/winadbasics'),
      PracticeLink('TryHackMe', 'Breaching Active Directory', 'https://tryhackme.com/room/breachingad'),
      PracticeLink('HTB Academy', 'Introduction to Active Directory', 'https://academy.hackthebox.com/course/preview/introduction-to-active-directory'),
    ],
  ),
];
