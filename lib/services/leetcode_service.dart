import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LeetCodeStats {
  const LeetCodeStats(this.username, this.easy, this.medium, this.hard, this.fetchedAt);
  final String username;
  final int easy, medium, hard;
  final DateTime fetchedAt;
  int get total => easy + medium + hard;

  Map<String, dynamic> toJson() =>
      {'u': username, 'e': easy, 'm': medium, 'h': hard, 'at': fetchedAt.toIso8601String()};
  static LeetCodeStats fromJson(Map<String, dynamic> j) => LeetCodeStats(
      j['u'], j['e'], j['m'], j['h'], DateTime.tryParse(j['at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0));

  /// Parses the `acSubmissionNum` list from LeetCode's public GraphQL API.
  static LeetCodeStats? fromGraphQL(String username, Map<String, dynamic> body, {DateTime? now}) {
    final user = body['data']?['matchedUser'];
    if (user == null) return null;
    final list = (user['submitStatsGlobal']?['acSubmissionNum'] as List?) ?? const [];
    int count(String d) {
      for (final e in list) {
        if (e is Map && e['difficulty'] == d) return (e['count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    }
    return LeetCodeStats(username, count('Easy'), count('Medium'), count('Hard'), now ?? DateTime.now());
  }
}

/// Imports solved-problem counts from LeetCode's public profile API.
/// TryHackMe and picoCTF have no public API, so they are logged manually.
class LeetCodeService {
  static const _kUser = 'cybertrack_leetcode_user';
  static const _kStats = 'cybertrack_leetcode_stats';

  static Future<String?> username() async => (await SharedPreferences.getInstance()).getString(_kUser);

  static Future<LeetCodeStats?> cached() async {
    final raw = (await SharedPreferences.getInstance()).getString(_kStats);
    if (raw == null) return null;
    try {
      return LeetCodeStats.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  /// Fetches fresh counts. Throws a readable message on failure.
  static Future<LeetCodeStats> sync(String user) async {
    final name = user.trim();
    if (name.isEmpty) throw 'Enter your LeetCode username.';
    const query = r'query userStats($username: String!) { matchedUser(username: $username) { submitStatsGlobal { acSubmissionNum { difficulty count } } } }';
    final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('https://leetcode.com/graphql'),
            headers: {
              'Content-Type': 'application/json',
              'Referer': 'https://leetcode.com/u/$name/',
              'User-Agent': 'Mozilla/5.0 (Android) CyberTrack/1.0',
            },
            body: jsonEncode({'query': query, 'variables': {'username': name}}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw 'Could not reach LeetCode. Check your connection.';
    }
    if (res.statusCode != 200) throw 'LeetCode returned an error (${res.statusCode}). Try again later.';
    final stats = LeetCodeStats.fromGraphQL(name, jsonDecode(res.body) as Map<String, dynamic>);
    if (stats == null) throw 'No LeetCode user called "$name".';
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUser, name);
    await p.setString(_kStats, jsonEncode(stats.toJson()));
    return stats;
  }
}
