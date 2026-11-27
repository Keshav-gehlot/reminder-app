import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

class NewsItem {
  NewsItem(this.title, this.url, this.source, this.published, this.cyber);
  final String title, url, source;
  final DateTime published;
  final bool cyber;

  Map<String, dynamic> toJson() =>
      {'t': title, 'u': url, 's': source, 'p': published.toIso8601String(), 'c': cyber};
  static NewsItem fromJson(Map<String, dynamic> j) =>
      NewsItem(j['t'], j['u'], j['s'], DateTime.parse(j['p']), j['c'] == true);
}

/// Daily tech news: 5 cybersecurity stories + up to 10 other tech stories,
/// never more than 15 in total. Cached for the day so it loads instantly.
class NewsService {
  static const maxCyber = 5;
  static const maxTotal = 15;
  static const _cacheKey = 'cybertrack_news_cache';

  static const _cyberFeeds = {
    'The Hacker News': 'https://feeds.feedburner.com/TheHackersNews',
    'BleepingComputer': 'https://www.bleepingcomputer.com/feed/',
  };
  static const _techFeeds = {
    'TechCrunch': 'https://techcrunch.com/feed/',
    'Ars Technica': 'https://feeds.arstechnica.com/arstechnica/index',
    'The Verge': 'https://www.theverge.com/rss/index.xml',
  };

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  /// Returns today's list, from cache when available unless [refresh] is true.
  static Future<List<NewsItem>> load({bool refresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!refresh) {
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        final j = jsonDecode(cached) as Map<String, dynamic>;
        if (j['day'] == _today()) {
          return (j['items'] as List).map((e) => NewsItem.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
    }
    final results = await Future.wait([
      for (final e in _cyberFeeds.entries) _fetch(e.key, e.value, true),
      for (final e in _techFeeds.entries) _fetch(e.key, e.value, false),
    ]);
    final items = select(results.expand((x) => x).toList());
    if (items.isNotEmpty) {
      await prefs.setString(_cacheKey, jsonEncode({'day': _today(), 'items': items.map((e) => e.toJson()).toList()}));
    }
    return items;
  }

  /// De-duplicates, sorts newest first, and applies the 5 cyber / 15 total caps.
  static List<NewsItem> select(List<NewsItem> all) {
    final seen = <String>{};
    final unique = all.where((i) => seen.add(i.title.toLowerCase())).toList()
      ..sort((a, b) => b.published.compareTo(a.published));
    final cyber = unique.where((i) => i.cyber).take(maxCyber).toList();
    final tech = unique.where((i) => !i.cyber).take(maxTotal - cyber.length).toList();
    return [...cyber, ...tech].take(maxTotal).toList();
  }

  static Future<List<NewsItem>> _fetch(String source, String url, bool cyber) async {
    try {
      final res = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0 (Android) CyberTrack/1.0'})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      return parseFeed(utf8.decode(res.bodyBytes, allowMalformed: true), source, cyber);
    } catch (_) {
      return [];
    }
  }

  /// Parses an RSS 2.0 or Atom document into news items (max 10 of each).
  static List<NewsItem> parseFeed(String xml, String source, bool cyber) {
    final doc = XmlDocument.parse(xml);
    final out = <NewsItem>[];
    for (final item in doc.findAllElements('item').take(10)) {
      final title = item.getElement('title')?.innerText.trim() ?? '';
      final link = item.getElement('link')?.innerText.trim() ?? '';
      final date = parseDate(item.getElement('pubDate')?.innerText ?? '');
      if (title.isNotEmpty && link.startsWith('http')) out.add(NewsItem(_clean(title), link, source, date, cyber));
    }
    for (final entry in doc.findAllElements('entry').take(10)) {
      final title = entry.getElement('title')?.innerText.trim() ?? '';
      final link = entry.findElements('link').map((l) => l.getAttribute('href') ?? '').firstWhere((h) => h.startsWith('http'), orElse: () => '');
      final date = parseDate(entry.getElement('updated')?.innerText ?? entry.getElement('published')?.innerText ?? '');
      if (title.isNotEmpty && link.isNotEmpty) out.add(NewsItem(_clean(title), link, source, date, cyber));
    }
    return out;
  }

  static String _clean(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&#8217;', '’')
      .replaceAll('&#8216;', '‘')
      .replaceAll('&quot;', '"')
      .replaceAll(RegExp(r'<[^>]+>'), '');

  static DateTime parseDate(String s) {
    final iso = DateTime.tryParse(s.trim());
    if (iso != null) return iso.toUtc();
    // RFC 822: "Mon, 23 Nov 2026 10:00:00 +0000" or "... GMT"
    final m = RegExp(r'(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{4}|\w+)?').firstMatch(s);
    if (m == null) return DateTime.fromMillisecondsSinceEpoch(0);
    const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    final mon = months.indexOf(m.group(2)!.toLowerCase()) + 1;
    var d = DateTime.utc(int.parse(m.group(3)!), mon == 0 ? 1 : mon, int.parse(m.group(1)!), int.parse(m.group(4)!),
        int.parse(m.group(5)!), int.tryParse(m.group(6) ?? '0') ?? 0);
    final tz = m.group(7) ?? '';
    if (RegExp(r'^[+-]\d{4}$').hasMatch(tz)) {
      final sign = tz.startsWith('-') ? -1 : 1;
      final off = Duration(hours: int.parse(tz.substring(1, 3)), minutes: int.parse(tz.substring(3, 5)));
      d = sign > 0 ? d.subtract(off) : d.add(off);
    }
    return d;
  }
}
