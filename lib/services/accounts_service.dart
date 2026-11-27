import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/workspace_store.dart';

/// External platforms a CyberTrack account can link to.
///
/// Linked handles and the last fetched stats are stored as workspace items
/// (kind `account`), so they sync to every device signed in to the same
/// CyberTrack account. Secret tokens (Hack The Box) never leave the device.
enum Platform { leetcode, tryhackme, hackthebox, picoctf, ctftime, codeforces, github }

class PlatformInfo {
  const PlatformInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.handleLabel,
    required this.help,
    required this.profileUrl,
    this.needsToken = false,
    this.manual = false,
  });
  final String name, handleLabel, help;
  final IconData icon;
  final Color color;
  final String Function(String handle) profileUrl;
  final bool needsToken; // needs a personal API token kept on this device
  final bool manual; // no public API: stats are entered by hand
}

const Map<Platform, PlatformInfo> platforms = {
  Platform.leetcode: PlatformInfo(
    name: 'LeetCode',
    icon: Icons.code,
    color: Color(0xFFD97706),
    handleLabel: 'Username',
    help: 'Your public LeetCode username. Reads solved counts and ranking.',
    profileUrl: _lcUrl,
  ),
  Platform.tryhackme: PlatformInfo(
    name: 'TryHackMe',
    icon: Icons.terminal,
    color: Color(0xFFC0392B),
    handleLabel: 'Username',
    help: 'Your TryHackMe username. The profile must be public. Reads rank, rooms, badges and streak.',
    profileUrl: _thmUrl,
  ),
  Platform.hackthebox: PlatformInfo(
    name: 'Hack The Box',
    icon: Icons.inventory_2_outlined,
    color: Color(0xFF5A8F00),
    handleLabel: 'App token',
    help: 'On HTB open Profile Settings → App Tokens → Create token, then paste it here. '
        'The token stays on this phone and is never synced.',
    profileUrl: _htbUrl,
    needsToken: true,
  ),
  Platform.picoctf: PlatformInfo(
    name: 'picoCTF',
    icon: Icons.flag_outlined,
    color: Color(0xFF2E5BBA),
    handleLabel: 'Username',
    help: 'picoCTF has no public API. Link your username and update your score and solves by hand.',
    profileUrl: _picoUrl,
    manual: true,
  ),
  Platform.ctftime: PlatformInfo(
    name: 'CTFtime',
    icon: Icons.emoji_events_outlined,
    color: Color(0xFFB91C1C),
    handleLabel: 'Team ID or team URL',
    help: 'Paste your team page URL (ctftime.org/team/12345) or just the number. Reads rating and world place.',
    profileUrl: _ctftimeUrl,
  ),
  Platform.codeforces: PlatformInfo(
    name: 'Codeforces',
    icon: Icons.leaderboard_outlined,
    color: Color(0xFF1F6FEB),
    handleLabel: 'Handle',
    help: 'Your Codeforces handle. Reads rating, max rating and rank.',
    profileUrl: _cfUrl,
  ),
  Platform.github: PlatformInfo(
    name: 'GitHub',
    icon: Icons.hub_outlined,
    color: Color(0xFF24292F),
    handleLabel: 'Username',
    help: 'Your GitHub username. Reads public repos and followers.',
    profileUrl: _ghUrl,
  ),
};

String _lcUrl(String h) => 'https://leetcode.com/u/$h/';
String _thmUrl(String h) => 'https://tryhackme.com/p/$h';
String _htbUrl(String h) => h.isEmpty ? 'https://app.hackthebox.com/profile/overview' : 'https://app.hackthebox.com/users/$h';
String _picoUrl(String h) => 'https://play.picoctf.org/users/$h';
String _ctftimeUrl(String h) => 'https://ctftime.org/team/$h';
String _cfUrl(String h) => 'https://codeforces.com/profile/$h';
String _ghUrl(String h) => 'https://github.com/$h';

/// Result of a sync: a headline number plus ordered stats.
class AccountStats {
  const AccountStats({required this.handle, required this.headline, required this.headlineLabel, required this.stats});
  final String handle; // display handle (for HTB: the username returned by the API)
  final String headline, headlineLabel;
  final Map<String, String> stats;
}

String _fmt(num? n) {
  if (n == null) return '—';
  final v = n is double && n != n.roundToDouble() ? n.toStringAsFixed(1) : n.round().toString();
  return v.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

/// Accepts a bare handle, "@handle" or a pasted profile URL.
String normalizeHandle(Platform p, String input) {
  var s = input.trim();
  if (p == Platform.hackthebox) return s; // token, keep as is
  s = s.replaceAll(RegExp(r'[?#].*$'), '').replaceAll(RegExp(r'/+$'), '');
  if (s.contains('/')) s = s.split('/').last;
  if (s.startsWith('@')) s = s.substring(1);
  if (p == Platform.ctftime) s = RegExp(r'\d+').firstMatch(s)?.group(0) ?? s;
  return s;
}

class AccountParsers {
  static AccountStats? leetcode(String handle, Map<String, dynamic> body) {
    final user = body['data']?['matchedUser'];
    if (user == null) return null;
    final list = (user['submitStatsGlobal']?['acSubmissionNum'] as List?) ?? const [];
    int count(String d) {
      for (final e in list) {
        if (e is Map && e['difficulty'] == d) return (e['count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    }
    final easy = count('Easy'), medium = count('Medium'), hard = count('Hard');
    return AccountStats(handle: handle, headline: _fmt(easy + medium + hard), headlineLabel: 'solved', stats: {
      'Easy': _fmt(easy),
      'Medium': _fmt(medium),
      'Hard': _fmt(hard),
      if (user['profile']?['ranking'] != null) 'Ranking': _fmt(user['profile']['ranking'] as num?),
    });
  }

  static AccountStats? tryhackme(String handle, Map<String, dynamic> body) {
    final d = body['data'];
    if (body['status'] != 'success' || d is! Map) return null;
    if (d['isPrivateProfile'] == true) throw 'This TryHackMe profile is private. Make it public in TryHackMe settings.';
    return AccountStats(handle: d['username']?.toString() ?? handle, headline: _fmt(d['completedRoomsNumber'] as num?), headlineLabel: 'rooms', stats: {
      'Rank': _fmt(d['rank'] as num?),
      if (d['topPercentage'] != null) 'Top': '${d['topPercentage']}%',
      'Points': _fmt(d['totalPoints'] as num?),
      'Badges': _fmt(d['badgesNumber'] as num?),
      'Level': _fmt(d['level'] as num?),
      'Streak': _fmt(d['streak'] as num?),
    });
  }

  static AccountStats? hackthebox(Map<String, dynamic> body) {
    final p = body['profile'];
    if (p is! Map) return null;
    return AccountStats(
      handle: p['name']?.toString() ?? '',
      headline: _fmt((p['system_owns'] as num? ?? 0) + (p['user_owns'] as num? ?? 0)),
      headlineLabel: 'owns',
      stats: {
        if (p['rank'] != null) 'Rank': p['rank'].toString(),
        'Global': p['ranking'] == null ? '—' : '#${_fmt(p['ranking'] as num?)}',
        'Points': _fmt(p['points'] as num?),
        'System': _fmt(p['system_owns'] as num?),
        'User': _fmt(p['user_owns'] as num?),
        'Respect': _fmt(p['respects'] as num?),
      },
    );
  }

  static AccountStats? ctftime(String id, Map<String, dynamic> body, {int? year}) {
    if (body['name'] == null) return null;
    final ratings = (body['rating'] as Map?) ?? const {};
    final y = (year ?? DateTime.now().year).toString();
    final now = ratings[y] as Map?;
    final prev = ratings[(int.parse(y) - 1).toString()] as Map?;
    return AccountStats(
      handle: body['name'].toString(),
      headline: now?['rating_place'] == null ? '—' : '#${_fmt(now!['rating_place'] as num?)}',
      headlineLabel: 'world $y',
      stats: {
        'Points $y': _fmt(now?['rating_points'] as num?),
        if (now?['country_place'] != null) 'Country': '#${_fmt(now!['country_place'] as num?)}',
        if (prev?['rating_place'] != null) 'Place ${int.parse(y) - 1}': '#${_fmt(prev!['rating_place'] as num?)}',
        'Team ID': id,
      },
    );
  }

  static AccountStats? codeforces(Map<String, dynamic> body) {
    if (body['status'] != 'OK') return null;
    final r = (body['result'] as List?)?.firstOrNull;
    if (r is! Map) return null;
    return AccountStats(handle: r['handle']?.toString() ?? '', headline: _fmt(r['rating'] as num?), headlineLabel: 'rating', stats: {
      'Rank': r['rank']?.toString() ?? 'unrated',
      'Max rating': _fmt(r['maxRating'] as num?),
      'Max rank': r['maxRank']?.toString() ?? '—',
    });
  }

  static AccountStats? github(Map<String, dynamic> body) {
    if (body['login'] == null) return null;
    return AccountStats(handle: body['login'].toString(), headline: _fmt(body['public_repos'] as num?), headlineLabel: 'repos', stats: {
      'Followers': _fmt(body['followers'] as num?),
      'Following': _fmt(body['following'] as num?),
      'Gists': _fmt(body['public_gists'] as num?),
    });
  }
}

class AccountsService {
  static const _ua = {'User-Agent': 'Mozilla/5.0 (Android) CyberTrack/1.0', 'Accept': 'application/json'};
  static String _tokenKey(Platform p) => 'cybertrack_token_${p.name}';
  static String itemId(Platform p) => 'account-${p.name}';

  static Map<String, dynamic>? linked(WorkspaceStore store, Platform p) {
    for (final e in store.ofKind('account')) {
      if (e['id'] == itemId(p)) return e;
    }
    return null;
  }

  static Future<String?> token(Platform p) async => (await SharedPreferences.getInstance()).getString(_tokenKey(p));

  static Future<Map<String, dynamic>> _json(Future<http.Response> req) async {
    final http.Response res;
    try {
      res = await req.timeout(const Duration(seconds: 15));
    } catch (_) {
      throw 'Could not connect. Check your internet and try again.';
    }
    if (res.statusCode == 401 || res.statusCode == 403) throw 'Access denied (${res.statusCode}). Check the token or that the profile is public.';
    if (res.statusCode == 404) throw 'Account not found.';
    if (res.statusCode == 429) throw 'Too many requests. Try again in a minute.';
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is Map<String, dynamic>) {
        if (res.statusCode >= 400) {
          throw (body['comment'] ?? body['message'] ?? 'Request failed (${res.statusCode}).').toString();
        }
        return body;
      }
    } on FormatException {
      // fall through
    }
    throw 'Unexpected reply (${res.statusCode}). The platform may have changed its API.';
  }

  /// Fetches fresh stats. [handle] is a username / id, or the token for HTB.
  static Future<AccountStats> fetch(Platform p, String handle) async {
    final h = normalizeHandle(p, handle);
    if (h.isEmpty) throw 'Enter your ${platforms[p]!.handleLabel.toLowerCase()}.';
    AccountStats? s;
    switch (p) {
      case Platform.leetcode:
        const q = r'query s($username: String!) { matchedUser(username: $username) { profile { ranking } submitStatsGlobal { acSubmissionNum { difficulty count } } } }';
        final body = await _json(http.post(Uri.parse('https://leetcode.com/graphql'),
            headers: {..._ua, 'Content-Type': 'application/json', 'Referer': 'https://leetcode.com/u/$h/'},
            body: jsonEncode({'query': q, 'variables': {'username': h}})));
        s = AccountParsers.leetcode(h, body);
        break;
      case Platform.tryhackme:
        s = AccountParsers.tryhackme(h, await _json(http.get(Uri.https('tryhackme.com', '/api/v2/public-profile', {'username': h}), headers: _ua)));
        break;
      case Platform.hackthebox:
        final auth = {..._ua, 'Authorization': 'Bearer $h'};
        final info = await _json(http.get(Uri.parse('https://labs.hackthebox.com/api/v4/user/info'), headers: auth));
        final id = info['info']?['id'];
        if (id == null) throw 'That token was not accepted by Hack The Box.';
        s = AccountParsers.hackthebox(await _json(http.get(Uri.parse('https://labs.hackthebox.com/api/v4/user/profile/basic/$id'), headers: auth)));
        if (s != null) s = AccountStats(handle: '${s.handle}#$id', headline: s.headline, headlineLabel: s.headlineLabel, stats: s.stats);
        break;
      case Platform.ctftime:
        if (int.tryParse(h) == null) throw 'Use the number from your team page, e.g. ctftime.org/team/12345.';
        s = AccountParsers.ctftime(h, await _json(http.get(Uri.parse('https://ctftime.org/api/v1/teams/$h/'), headers: _ua)));
        break;
      case Platform.codeforces:
        s = AccountParsers.codeforces(await _json(http.get(Uri.https('codeforces.com', '/api/user.info', {'handles': h}), headers: _ua)));
        break;
      case Platform.github:
        s = AccountParsers.github(await _json(http.get(Uri.https('api.github.com', '/users/$h'), headers: {..._ua, 'Accept': 'application/vnd.github+json'})));
        break;
      case Platform.picoctf:
        throw 'picoCTF has no public API. Update your score by hand.';
    }
    if (s == null) throw 'No ${platforms[p]!.name} account found for "$h".';
    return s;
  }

  /// Links (or re-syncs) an account and saves it to the synced workspace.
  static Future<void> link(WorkspaceStore store, Platform p, String handle) async {
    final info = platforms[p]!;
    final s = await fetch(p, handle);
    String publicHandle = normalizeHandle(p, handle);
    if (info.needsToken) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey(p), handle.trim());
      publicHandle = s.handle.contains('#') ? s.handle.split('#').last : '';
    }
    await save(store, p, publicHandle, s);
  }

  static Future<void> save(WorkspaceStore store, Platform p, String handle, AccountStats s) => store.upsert({
        ...?linked(store, p),
        'id': itemId(p),
        'kind': 'account',
        'platform': p.name,
        'handle': handle,
        'display': s.handle.split('#').first,
        'headline': s.headline,
        'headlineLabel': s.headlineLabel,
        'stats': s.stats,
        'fetchedAt': DateTime.now().toUtc().toIso8601String(),
      });

  /// Manual entry for platforms without an API (picoCTF).
  static Future<void> saveManual(WorkspaceStore store, Platform p, String handle, int score, int solved) =>
      save(store, p, normalizeHandle(p, handle),
          AccountStats(handle: normalizeHandle(p, handle), headline: _fmt(score), headlineLabel: 'points', stats: {'Solved': _fmt(solved)}));

  static Future<void> refresh(WorkspaceStore store, Platform p) async {
    final item = linked(store, p);
    if (item == null) return;
    final info = platforms[p]!;
    if (info.manual) return;
    final key = info.needsToken ? await token(p) : item['handle']?.toString();
    if (key == null || key.isEmpty) throw 'Add your ${info.name} ${info.handleLabel.toLowerCase()} on this phone to refresh.';
    final s = await fetch(p, key);
    await save(store, p, item['handle']?.toString() ?? '', s);
  }

  static Future<void> unlink(WorkspaceStore store, Platform p) async {
    final item = linked(store, p);
    if (item != null) await store.remove(item);
    await (await SharedPreferences.getInstance()).remove(_tokenKey(p));
  }

  /// Moves the LeetCode username saved by build 41 into a linked account.
  static Future<void> migrateLegacy(WorkspaceStore store) async {
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getString('cybertrack_leetcode_user');
    if (old == null) return;
    await prefs.remove('cybertrack_leetcode_user');
    await prefs.remove('cybertrack_leetcode_stats');
    if (linked(store, Platform.leetcode) != null) return;
    try {
      await link(store, Platform.leetcode, old);
    } catch (_) {}
  }

  /// Quietly refreshes linked accounts older than [maxAge]. Errors are ignored.
  static Future<void> refreshStale(WorkspaceStore store, {Duration maxAge = const Duration(hours: 12)}) async {
    for (final p in Platform.values) {
      final item = linked(store, p);
      if (item == null || platforms[p]!.manual) continue;
      final at = DateTime.tryParse(item['fetchedAt']?.toString() ?? '');
      if (at != null && DateTime.now().toUtc().difference(at) < maxAge) continue;
      try {
        await refresh(store, p);
      } catch (_) {}
    }
  }
}
