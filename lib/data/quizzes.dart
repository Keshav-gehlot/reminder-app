// Three quick check-your-understanding questions per topic.

class QuizQuestion {
  const QuizQuestion(this.q, this.options, this.answer, this.why);
  final String q;
  final List<String> options;
  final int answer;
  final String why;
}

const Map<String, List<QuizQuestion>> quizzes = {
  // ─────────────── DSA ───────────────
  'Arrays and hash maps': [
    QuizQuestion('Average time to look up a key in a hash map?', ['O(1)', 'O(log n)', 'O(n)', 'O(n²)'], 0, 'Hashing jumps straight to the bucket.'),
    QuizQuestion('In Two Sum, why check for the complement before inserting the current value?', ['It is faster', 'To avoid pairing an element with itself', 'To keep the map sorted', 'To save memory'], 1, 'Checking first means index i can only match earlier indices.'),
    QuizQuestion('Hash-map Two Sum uses how much extra space?', ['O(1)', 'O(log n)', 'O(n)', 'O(n²)'], 2, 'In the worst case every value is stored.'),
  ],
  'Two pointers': [
    QuizQuestion('Two pointers on Two Sum II works because the array is…', ['Small', 'Sorted', 'Unique', 'Positive'], 1, 'Sorted order tells you which pointer to move.'),
    QuizQuestion('If a[L] + a[R] is too small, you should…', ['Move R left', 'Move L right', 'Move both', 'Restart'], 1, 'Moving L right increases the sum.'),
    QuizQuestion('Extra space used by the two-pointer solution?', ['O(1)', 'O(n)', 'O(log n)', 'O(n²)'], 0, 'Only two indices are stored.'),
  ],
  'Sliding window': [
    QuizQuestion('A sliding window always covers…', ['Any subset', 'A contiguous range', 'Sorted elements', 'Unique elements'], 1, 'Windows are contiguous subarrays.'),
    QuizQuestion('Why is the variable window O(n) despite a nested while loop?', ['The array is sorted', 'Each index enters and leaves once', 'It uses a hash map', 'It skips elements'], 1, 'L and R each move at most n times.'),
    QuizQuestion('The shrink-from-left trick for "sum ≥ target" relies on values being…', ['Sorted', 'Positive', 'Unique', 'Even'], 1, 'With negatives, shrinking could increase the sum.'),
  ],
  'Binary search': [
    QuizQuestion('Steps to search 1,000,000 sorted items?', ['About 20', 'About 1,000', 'About 500,000', '1,000,000'], 0, 'log₂(1,000,000) ≈ 20.'),
    QuizQuestion('Why write mid = lo + (hi - lo) // 2?', ['It is faster', 'Avoids integer overflow', 'Rounds up', 'Required by Python'], 1, '(lo + hi) can overflow in fixed-width integers.'),
    QuizQuestion('Binary search needs the data to be…', ['Unique', 'Sorted or monotonic', 'Small', 'Numeric'], 1, 'You must know which half to discard.'),
  ],
  'Stacks': [
    QuizQuestion('A stack follows…', ['FIFO', 'LIFO', 'Priority order', 'Random order'], 1, 'Last in, first out.'),
    QuizQuestion('"(]" is invalid because…', ['Too short', 'Closing bracket does not match the top', 'Brackets must be equal', 'Stack is empty at start'], 1, '] must match [ but the top is (.'),
    QuizQuestion('After processing a valid bracket string, the stack is…', ['Full', 'Empty', 'Sorted', 'Size 1'], 1, 'Every opener was matched and popped.'),
  ],
  'Linked lists': [
    QuizQuestion('Accessing the k-th node of a singly linked list costs…', ['O(1)', 'O(log n)', 'O(k)', 'O(k²)'], 2, 'You must walk k pointers.'),
    QuizQuestion('When reversing, what must you save before changing cur.next?', ['prev', 'cur.next', 'head', 'tail'], 1, 'Otherwise the rest of the list is lost.'),
    QuizQuestion('After reversing iteratively, the new head is…', ['cur', 'prev', 'head', 'null'], 1, 'cur ends at null; prev holds the last node.'),
  ],
  'Trees: BFS level order': [
    QuizQuestion('Level-order traversal uses a…', ['Stack', 'Queue', 'Heap', 'Hash map'], 1, 'FIFO processes nodes by depth.'),
    QuizQuestion('How do you separate levels in BFS?', ['Track depth in a map', 'Snapshot the queue size each round', 'Sort the queue', 'Use recursion'], 1, 'Process exactly that many nodes per level.'),
    QuizQuestion('Inorder traversal visits…', ['Node, left, right', 'Left, node, right', 'Left, right, node', 'By level'], 1, 'Inorder = left subtree, node, right subtree.'),
  ],
  'Graphs: BFS and DFS': [
    QuizQuestion('Why keep a visited set?', ['Speed up sorting', 'Avoid infinite loops on cycles', 'Store weights', 'Find the root'], 1, 'Graphs can revisit nodes through cycles.'),
    QuizQuestion('Which finds shortest paths in an unweighted graph?', ['DFS', 'BFS', 'Both equally', 'Neither'], 1, 'BFS explores by distance layers.'),
    QuizQuestion('Time complexity of BFS/DFS with an adjacency list?', ['O(V)', 'O(E)', 'O(V + E)', 'O(V·E)'], 2, 'Each vertex and edge is processed once.'),
  ],
  'Dynamic programming': [
    QuizQuestion('DP helps when a problem has…', ['Sorted input', 'Overlapping subproblems', 'No recursion', 'Only integers'], 1, 'Stored answers prevent repeated work.'),
    QuizQuestion('ways(5) for climbing stairs (1 or 2 steps)?', ['5', '7', '8', '13'], 2, '1, 1, 2, 3, 5, 8.'),
    QuizQuestion('Space for climbing stairs after optimisation?', ['O(1)', 'O(n)', 'O(n²)', 'O(log n)'], 0, 'Only the last two values are needed.'),
  ],
  'Backtracking': [
    QuizQuestion('How many subsets does a set of n elements have?', ['n', 'n²', '2ⁿ', 'n!'], 2, 'Each element is in or out.'),
    QuizQuestion('The backtracking pattern is…', ['Sort, search, return', 'Choose, explore, un-choose', 'Divide, merge', 'Push, pop'], 1, 'Undo the choice after exploring it.'),
    QuizQuestion('Why append path[:] instead of path?', ['Faster', 'Save a copy, not a reference that changes later', 'Python requires it', 'Sorts the path'], 1, 'The same list keeps being modified.'),
  ],
  'Heaps and priority queues': [
    QuizQuestion('In a min-heap, the root holds…', ['The largest value', 'The smallest value', 'The median', 'The newest value'], 1, 'Every parent ≤ its children.'),
    QuizQuestion('To keep the k largest elements, use a…', ['Max-heap of size n', 'Min-heap of size k', 'Sorted array', 'Stack'], 1, 'Pop the smallest whenever size exceeds k.'),
    QuizQuestion('Cost of push/pop on a binary heap?', ['O(1)', 'O(log n)', 'O(n)', 'O(n log n)'], 1, 'Sift up/down along the tree height.'),
  ],
  'Big-O and complexity': [
    QuizQuestion('O(3n² + 5n + 2) simplifies to…', ['O(n)', 'O(n²)', 'O(3n²)', 'O(n³)'], 1, 'Drop constants and smaller terms.'),
    QuizQuestion('A loop that halves n each step is…', ['O(n)', 'O(log n)', 'O(n log n)', 'O(1)'], 1, 'n reaches 1 after log₂ n halvings.'),
    QuizQuestion('n = 10⁵: which is too slow?', ['O(n)', 'O(n log n)', 'O(n²)', 'O(log n)'], 2, '10¹⁰ operations takes far too long.'),
  ],
  'Prefix sums': [
    QuizQuestion('With prefix[0] = 0, sum of nums[l..r] is…', ['prefix[r] − prefix[l]', 'prefix[r+1] − prefix[l]', 'prefix[r] + prefix[l]', 'prefix[r+1]'], 1, 'prefix[i] is the sum of the first i elements.'),
    QuizQuestion('Query time after building prefix sums?', ['O(1)', 'O(log n)', 'O(n)', 'O(n²)'], 0, 'One subtraction.'),
    QuizQuestion('"Subarray sum equals k" combines prefix sums with…', ['A stack', 'A hash map', 'A heap', 'Sorting'], 1, 'Count earlier prefix sums equal to current − k.'),
  ],
  'Recursion': [
    QuizQuestion('Every recursive function needs…', ['A loop', 'A base case', 'Two calls', 'Global variables'], 1, 'Otherwise it never stops.'),
    QuizQuestion('Missing base case usually causes…', ['Wrong answer', 'Stack overflow', 'Compile error', 'Faster code'], 1, 'Calls pile up until the stack runs out.'),
    QuizQuestion('Space used by recursive fact(n)?', ['O(1)', 'O(log n)', 'O(n)', 'O(n²)'], 2, 'n frames on the call stack.'),
  ],
  'Sorting: merge sort': [
    QuizQuestion('Merge sort time complexity?', ['O(n)', 'O(n log n)', 'O(n²)', 'O(log n)'], 1, 'log n levels × O(n) merging.'),
    QuizQuestion('Merging two sorted halves uses…', ['Binary search', 'Two pointers', 'A heap', 'Hashing'], 1, 'Compare the fronts and take the smaller.'),
    QuizQuestion('Main drawback of merge sort?', ['Unstable', 'O(n) extra space', 'O(n²) worst case', 'Needs sorted input'], 1, 'Merging needs a temporary array.'),
  ],
  'Queues and deques': [
    QuizQuestion('A queue follows…', ['LIFO', 'FIFO', 'Priority', 'Random'], 1, 'First in, first out.'),
    QuizQuestion('In sliding window maximum, the deque front is…', ['The newest index', 'The current window maximum', 'The smallest value', 'Always index 0'], 1, 'Smaller values are popped from the back.'),
    QuizQuestion('Sliding window maximum with a deque runs in…', ['O(n·k)', 'O(n log k)', 'O(n)', 'O(k)'], 2, 'Each index is pushed and popped once.'),
  ],
  'Monotonic stack': [
    QuizQuestion('Daily Temperatures keeps a stack of…', ['Temperatures sorted ascending', 'Indices still waiting for a warmer day', 'Answers', 'Visited days'], 1, 'Pop when a warmer day resolves them.'),
    QuizQuestion('Overall time of the monotonic stack solution?', ['O(n²)', 'O(n log n)', 'O(n)', 'O(1)'], 2, 'Each index is pushed and popped once.'),
    QuizQuestion('Which problem also uses a monotonic stack?', ['Two Sum', 'Next greater element', 'Binary search', 'Merge intervals'], 1, 'Same next-greater pattern.'),
  ],
  'Binary search trees': [
    QuizQuestion('Inorder traversal of a valid BST is…', ['Random', 'Sorted ascending', 'Sorted descending', 'Level order'], 1, 'Left < node < right everywhere.'),
    QuizQuestion('Why is checking only a node and its children not enough?', ['It is slow', 'A deep node can break an ancestor bound', 'Children may be null', 'BSTs are unbalanced'], 1, 'Each node must fit all ancestor ranges.'),
    QuizQuestion('Search in a skewed (list-like) BST costs…', ['O(1)', 'O(log n)', 'O(n)', 'O(n log n)'], 2, 'Height becomes n.'),
  ],
  'Tries (prefix trees)': [
    QuizQuestion('Trie insert cost depends on…', ['Number of words', 'Word length', 'Alphabet size only', 'Tree height of all words'], 1, 'One node per character.'),
    QuizQuestion('search("car") vs startsWith("car") differs in…', ['Nothing', 'search needs the end-of-word mark', 'startsWith is slower', 'search ignores case'], 1, '"cart" contains the prefix but not the word.'),
    QuizQuestion('A classic use of tries is…', ['Sorting numbers', 'Autocomplete', 'Shortest paths', 'Hashing passwords'], 1, 'Prefix lookups are fast.'),
  ],
  'Intervals': [
    QuizQuestion('First step to merge intervals?', ['Sort by end', 'Sort by start', 'Use a stack', 'Hash them'], 1, 'Overlaps become adjacent.'),
    QuizQuestion('[1,4] and [4,5] are…', ['Separate', 'Overlapping (touching)', 'Invalid', 'Nested'], 1, 'start 4 ≤ end 4, so they merge to [1,5].'),
    QuizQuestion('Merging [1,10] then [2,3] should give…', ['[1,3]', '[1,10]', '[2,10]', '[1,10],[2,3]'], 1, 'Take the max of the ends.'),
  ],
  'Greedy algorithms': [
    QuizQuestion('Greedy algorithms make…', ['Exhaustive searches', 'The best local choice each step', 'Random choices', 'Recursive splits'], 1, 'They never revisit choices.'),
    QuizQuestion('Coin change with arbitrary coins should use…', ['Greedy', 'Dynamic programming', 'Binary search', 'A stack'], 1, 'Greedy can fail, e.g. coins 1, 3, 4 for 6.'),
    QuizQuestion('In Jump Game, the greedy idea is to…', ['Try every path', 'Move the goal backwards when reachable', 'Sort the array', 'Always jump the max'], 1, 'If i can reach the goal, i becomes the new goal.'),
  ],
  'Grid graphs': [
    QuizQuestion('In a grid graph, each cell\'s neighbours are usually…', ['All cells', 'Up, down, left, right', 'Diagonals only', 'The same row'], 1, '4-directional adjacency.'),
    QuizQuestion('Number of Islands counts…', ['Land cells', 'Times a new unvisited land cell starts a flood fill', 'Water cells', 'Rows'], 1, 'Each flood fill marks one island.'),
    QuizQuestion('Time complexity for an R×C grid?', ['O(R + C)', 'O(R·C)', 'O((R·C)²)', 'O(log RC)'], 1, 'Each cell is visited once.'),
  ],
  'Topological sort': [
    QuizQuestion('Topological order exists only for…', ['Undirected graphs', 'Directed acyclic graphs', 'Trees', 'Weighted graphs'], 1, 'A cycle has no valid order.'),
    QuizQuestion('Kahn\'s algorithm starts with nodes of…', ['Highest degree', 'In-degree 0', 'Out-degree 0', 'Lowest label'], 1, 'They have no prerequisites.'),
    QuizQuestion('If the order has fewer than n nodes…', ['Graph is a tree', 'There is a cycle', 'Graph is weighted', 'It is complete'], 1, 'Cycle nodes never reach in-degree 0.'),
  ],
  'Union-find': [
    QuizQuestion('Union-find answers…', ['Shortest paths', 'Whether two nodes are in the same group', 'Sorted order', 'Max flow'], 1, 'find(a) == find(b).'),
    QuizQuestion('Path compression makes find…', ['Slower', 'Point nodes closer to the root', 'Sort the parents', 'Use more memory'], 1, 'Later finds are almost O(1).'),
    QuizQuestion('A union that finds both nodes already connected indicates…', ['A bug', 'A cycle in an undirected graph', 'A disconnected graph', 'A tree'], 1, 'Used for Redundant Connection.'),
  ],
  'Shortest paths: Dijkstra': [
    QuizQuestion('Dijkstra requires edge weights to be…', ['Integers', 'Non-negative', 'Unique', 'Sorted'], 1, 'Negative edges break the greedy choice.'),
    QuizQuestion('Dijkstra pops the node with…', ['Most edges', 'Smallest known distance', 'Largest label', 'Newest insertion'], 1, 'Min-heap by distance.'),
    QuizQuestion('For negative edges use…', ['BFS', 'Bellman-Ford', 'DFS', 'Prim'], 1, 'Bellman-Ford handles negatives.'),
  ],
  '2D dynamic programming': [
    QuizQuestion('LCS of "ace" and "abcde"?', ['2', '3', '4', '5'], 1, '"ace" is a subsequence of both.'),
    QuizQuestion('If a[i-1] == b[j-1], dp[i][j] = …', ['max(top, left)', 'dp[i-1][j-1] + 1', 'dp[i-1][j] + 1', '0'], 1, 'Extend the diagonal.'),
    QuizQuestion('LCS time complexity?', ['O(m + n)', 'O(m·n)', 'O(2ⁿ)', 'O(n log n)'], 1, 'Fill an m×n table.'),
  ],
  'Bit manipulation': [
    QuizQuestion('x ^ x equals…', ['x', '0', '1', '2x'], 1, 'XOR cancels identical bits.'),
    QuizQuestion('n & (n − 1)…', ['Doubles n', 'Removes the lowest set bit', 'Sets all bits', 'Flips n'], 1, 'Used to count set bits.'),
    QuizQuestion('5 << 1 equals…', ['2', '5', '10', '25'], 2, 'Shift left multiplies by 2.'),
  ],

  // ─────────────── CTF ───────────────
  'Forensics: file signatures': [
    QuizQuestion('A file starts with 89 50 4E 47. It is a…', ['JPEG', 'PNG', 'ZIP', 'PDF'], 1, 'That is the PNG signature.'),
    QuizQuestion('First thing to do with evidence?', ['Open it', 'Hash it and work on a copy', 'Rename it', 'Upload it'], 1, 'Preserve integrity.'),
    QuizQuestion('DOCX and APK files start with the signature of…', ['PDF', 'ZIP', 'ELF', 'GIF'], 1, 'They are ZIP containers.'),
  ],
  'Crypto: XOR': [
    QuizQuestion('If C = P ⊕ K, then P = …', ['C + K', 'C ⊕ K', 'K ⊕ K', 'C − K'], 1, 'XOR is its own inverse.'),
    QuizQuestion('How many keys must you try for single-byte XOR?', ['16', '128', '256', '65,536'], 2, 'One byte has 256 values.'),
    QuizQuestion('Repeating-key XOR is broken by first finding…', ['The flag format', 'The key length', 'The file type', 'The IV'], 1, 'Then solve each column as single-byte XOR.'),
  ],
  'Network: PCAP triage': [
    QuizQuestion('Best first step with a large PCAP?', ['Read packets one by one', 'Statistics: protocol hierarchy and conversations', 'Export all files', 'Delete noise'], 1, 'Get the big picture first.'),
    QuizQuestion('Wireshark filter for HTTP requests?', ['http.response', 'http.request', 'tcp.port == 22', 'dns'], 1, 'http.request shows GET/POST etc.'),
    QuizQuestion('Many DNS queries to random-looking domains may indicate…', ['Normal browsing', 'Malware beaconing or DGA', 'A printer', 'Slow Wi-Fi'], 1, 'Domain generation algorithms look random.'),
  ],
  'Web: reconnaissance and HTTP': [
    QuizQuestion('Before any testing you must confirm…', ['Your IP', 'Scope and rules of engagement', 'Server OS', 'Open ports'], 1, 'Scope keeps you legal.'),
    QuizQuestion('robots.txt is…', ['Permission to access paths', 'A hint about paths, not permission', 'A firewall', 'A password file'], 1, 'It only asks crawlers to skip paths.'),
    QuizQuestion('Where might API routes be revealed?', ['CSS files', 'JavaScript bundles', 'Favicon', 'DNS TTL'], 1, 'Front-end code often lists endpoints.'),
  ],
  'Web: SQL injection': [
    QuizQuestion('Root cause of SQL injection?', ['Weak passwords', 'Mixing user input into query code', 'HTTPS missing', 'Old browsers'], 1, 'Input changes query structure.'),
    QuizQuestion('The correct fix is…', ['Blocking quotes', 'Parameterized queries', 'Longer passwords', 'Hiding errors only'], 1, 'Bound parameters are never parsed as SQL.'),
    QuizQuestion('Least-privilege DB accounts help by…', ['Preventing injection', 'Limiting damage if injection happens', 'Speeding queries', 'Encrypting data'], 1, 'Defence in depth.'),
  ],
  'Web: cross-site scripting (XSS)': [
    QuizQuestion('Stored XSS payloads live…', ['In the URL only', 'On the server, shown to other users', 'In cookies only', 'In DNS'], 1, 'Saved and served to victims.'),
    QuizQuestion('Main fix for XSS?', ['Input length limits', 'Context-aware output encoding', 'HTTPS', 'Captcha'], 1, 'Encode for HTML, attribute or JS context.'),
    QuizQuestion('Safer than innerHTML for plain text?', ['outerHTML', 'textContent', 'document.write', 'eval'], 1, 'textContent never parses HTML.'),
  ],
  'Linux permissions': [
    QuizQuestion('Octal 754 means owner/group/others =', ['rwx/r-x/r--', 'rw-/r-x/r--', 'rwx/rw-/r--', 'r-x/r-x/r--'], 0, '7=rwx, 5=r-x, 4=r--.'),
    QuizQuestion('An "s" in the owner execute slot means…', ['Sticky bit', 'SUID: runs as the file owner', 'Symlink', 'Socket'], 1, 'Often root, hence the risk.'),
    QuizQuestion('Command to find SUID files?', ['ls -la /', 'find / -perm -4000', 'chmod -R', 'ps aux'], 1, '-4000 is the SUID bit.'),
  ],
  'Reverse engineering basics': [
    QuizQuestion('Where should you analyse an unknown binary?', ['Your main laptop', 'An isolated VM with snapshots', 'A shared server', 'Your phone'], 1, 'Contain anything malicious.'),
    QuizQuestion('Ghidra is mainly a…', ['Debugger', 'Disassembler/decompiler', 'Packet sniffer', 'Fuzzer'], 1, 'Static analysis tool.'),
    QuizQuestion('If input[i] ^ 0x13 == secret[i], the password byte is…', ['secret[i] + 0x13', 'secret[i] ^ 0x13', 'secret[i] − 0x13', '0x13'], 1, 'Undo the XOR.'),
  ],
  'Binary exploitation basics': [
    QuizQuestion('Why is gets() dangerous?', ['It is slow', 'It never checks input length', 'It needs root', 'It only reads numbers'], 1, 'Unbounded copy into a fixed buffer.'),
    QuizQuestion('Overflowing past a stack buffer can overwrite the…', ['Heap', 'Return address', 'Kernel', 'GOT only'], 1, 'Control flow follows it on return.'),
    QuizQuestion('NX / DEP prevents…', ['Reading memory', 'Executing code on the stack', 'Writing files', 'Network access'], 1, 'Injected shellcode can\'t run there.'),
  ],
  'OSINT investigations': [
    QuizQuestion('First check on a photo in an OSINT challenge?', ['Brute force', 'Metadata with exiftool', 'Port scan', 'SQL injection'], 1, 'GPS and device data often hide there.'),
    QuizQuestion('Same username on two sites is…', ['Proof', 'A weak signal needing more evidence', 'Illegal to check', 'Always wrong'], 1, 'Confirm with photo, style or location.'),
    QuizQuestion('Tool to check a username across many sites?', ['Wireshark', 'Sherlock', 'Ghidra', 'Nmap'], 1, 'Sherlock enumerates usernames.'),
  ],
  'Steganography': [
    QuizQuestion('LSB steganography hides data in…', ['File names', 'The least significant bits of pixel values', 'EXIF only', 'Compression headers'], 1, 'Tiny colour changes carry bits.'),
    QuizQuestion('A good tool for PNG bit planes?', ['steghide', 'zsteg', 'nmap', 'sqlmap'], 1, 'steghide supports JPEG/BMP/WAV, not PNG.'),
    QuizQuestion('Hidden audio messages are often seen in a…', ['Hex dump', 'Spectrogram', 'Waveform zoom', 'Metadata'], 1, 'Text can be drawn in frequencies.'),
  ],
  'Active Directory basics': [
    QuizQuestion('The domain controller…', ['Hosts websites', 'Stores accounts and authenticates logins', 'Routes packets', 'Is a firewall'], 1, 'Central identity for the domain.'),
    QuizQuestion('Kerberos authenticates users with…', ['Passwords sent each time', 'Tickets', 'Cookies', 'Certificates only'], 1, 'TGT then service tickets.'),
    QuizQuestion('Kerberoasting targets…', ['Weak service account passwords', 'Open RDP', 'DNS servers', 'Printers'], 0, 'Service tickets can be cracked offline.'),
  ],

  // ─────────────── AI / ML ───────────────
  'AI, ML and deep learning': [
    QuizQuestion('Which is correct?', ['ML ⊃ AI', 'AI ⊃ ML ⊃ DL', 'DL ⊃ AI', 'They are unrelated'], 1, 'Nested fields.'),
    QuizQuestion('Learning from labelled examples is…', ['Unsupervised', 'Supervised', 'Reinforcement', 'Rule-based'], 1, 'Labels supervise the model.'),
    QuizQuestion('Grouping customers without labels is…', ['Supervised', 'Unsupervised', 'Reinforcement', 'Regression'], 1, 'Clustering finds structure.'),
  ],
  'Linear regression': [
    QuizQuestion('Linear regression predicts…', ['Categories', 'A continuous number', 'Clusters', 'Tokens'], 1, 'e.g. house price.'),
    QuizQuestion('"Best fit" usually minimises…', ['Accuracy', 'Mean squared error', 'Recall', 'Entropy'], 1, 'Average of squared residuals.'),
    QuizQuestion('R² = 1.0 means…', ['No fit', 'Perfect fit', 'Overfit always', 'Negative slope'], 1, 'Explains all variation.'),
  ],
  'Gradient descent': [
    QuizQuestion('Gradient descent steps…', ['Along the gradient', 'Opposite the gradient', 'Randomly', 'Toward zero weights'], 1, 'The gradient points uphill.'),
    QuizQuestion('A learning rate that is too large can…', ['Converge faster always', 'Overshoot and diverge', 'Freeze weights', 'Reduce data'], 1, 'Steps jump past the minimum.'),
    QuizQuestion('Most common variant in deep learning?', ['Full-batch GD', 'Mini-batch GD (e.g. Adam)', 'Exhaustive search', 'Newton only'], 1, 'Balances speed and stability.'),
  ],
  'Logistic regression': [
    QuizQuestion('Logistic regression is used for…', ['Regression of prices', 'Classification', 'Clustering', 'Sorting'], 1, 'Despite the name.'),
    QuizQuestion('sigmoid(0) equals…', ['0', '0.5', '1', '−1'], 1, 'Midpoint of the S-curve.'),
    QuizQuestion('Its usual loss function is…', ['MSE', 'Cross-entropy (log loss)', 'Hinge', 'L1'], 1, 'Punishes confident wrong answers.'),
  ],
  'Evaluating models': [
    QuizQuestion('99% train accuracy, 70% test accuracy suggests…', ['Underfitting', 'Overfitting', 'Perfect model', 'Data leak fixed'], 1, 'Memorised the training set.'),
    QuizQuestion('Recall = …', ['TP / (TP + FP)', 'TP / (TP + FN)', 'TN / all', '(TP + TN) / all'], 1, 'Share of real positives caught.'),
    QuizQuestion('With 1% malware, accuracy is misleading because…', ['It is slow', 'Always predicting "clean" scores 99%', 'Malware is rare online', 'Accuracy needs labels'], 1, 'Class imbalance.'),
  ],
  'Decision trees and forests': [
    QuizQuestion('A split is chosen to…', ['Balance tree depth', 'Make groups purer (lower Gini/entropy)', 'Sort features', 'Use all data'], 1, 'Biggest impurity drop wins.'),
    QuizQuestion('Random forests reduce…', ['Bias only', 'Variance by averaging many trees', 'Training data', 'Features'], 1, 'Voting smooths individual errors.'),
    QuizQuestion('Main risk of a very deep single tree?', ['Underfitting', 'Overfitting', 'Slow prediction', 'No splits'], 1, 'It memorises noise.'),
  ],
  'K-means clustering': [
    QuizQuestion('K-means is…', ['Supervised', 'Unsupervised', 'Reinforcement', 'A neural network'], 1, 'No labels needed.'),
    QuizQuestion('After assigning points, centroids move to…', ['A random point', 'The mean of their points', 'The origin', 'The farthest point'], 1, 'Assign → update loop.'),
    QuizQuestion('A common way to choose k?', ['Always 3', 'Elbow method / silhouette', 'Number of features', 'Random'], 1, 'Look for the bend in error vs k.'),
  ],
  'Neural networks': [
    QuizQuestion('A neuron computes…', ['A sort', 'Weighted sum + bias, then activation', 'A hash', 'A max only'], 1, 'Then passes the result on.'),
    QuizQuestion('Without non-linear activations, deep networks…', ['Train faster', 'Collapse to a single linear model', 'Overfit more', 'Need more data'], 1, 'Linear of linear is linear.'),
    QuizQuestion('Multi-class output layers usually use…', ['ReLU', 'Softmax', 'Tanh', 'None'], 1, 'Probabilities summing to 1.'),
  ],
  'Backpropagation': [
    QuizQuestion('Backpropagation computes…', ['Predictions', 'Gradients of the loss for every weight', 'The learning rate', 'Batch size'], 1, 'Via the chain rule.'),
    QuizQuestion('It works backwards from…', ['Input to output', 'Output to input', 'Middle outward', 'Randomly'], 1, 'Errors flow back layer by layer.'),
    QuizQuestion('Vanishing gradients are reduced by…', ['Sigmoid everywhere', 'ReLU and residual connections', 'Bigger batches only', 'Removing bias'], 1, 'Keeps gradients from shrinking.'),
  ],
  'Convolutional networks (CNNs)': [
    QuizQuestion('CNNs need fewer parameters because…', ['They skip training', 'Filters share weights across the image', 'They use small images', 'No bias terms'], 1, 'One 3×3 filter slides everywhere.'),
    QuizQuestion('Pooling layers…', ['Add colour', 'Downsample while keeping strong signals', 'Normalise labels', 'Increase size'], 1, 'Max or average of small regions.'),
    QuizQuestion('Early conv layers typically detect…', ['Whole objects', 'Edges and simple textures', 'Labels', 'Text'], 1, 'Later layers combine them.'),
  ],
  'Transformers and LLMs': [
    QuizQuestion('GPT-style models generate text by…', ['Copying the web', 'Predicting the next token repeatedly', 'Sorting words', 'Looking up answers'], 1, 'Autoregressive generation.'),
    QuizQuestion('Attention lets each token…', ['Skip training', 'Weigh information from other tokens', 'Compress images', 'Run faster'], 1, 'Query · key scores mix values.'),
    QuizQuestion('A security risk specific to LLM apps?', ['SQL injection only', 'Prompt injection', 'Buffer overflow only', 'ARP spoofing'], 1, 'Untrusted text can act as instructions.'),
  ],
};
