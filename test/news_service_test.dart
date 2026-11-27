import 'package:cybertrack12/services/news_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses RSS items with RFC 822 dates', () {
    const rss = '''<?xml version="1.0"?><rss><channel>
      <item><title>Patch now &amp; stay safe</title><link>https://a.example/1</link><pubDate>Fri, 27 Nov 2026 10:30:00 +0530</pubDate></item>
      <item><title></title><link>https://a.example/2</link></item>
      <item><title>No link</title><link>notaurl</link></item>
    </channel></rss>''';
    final items = NewsService.parseFeed(rss, 'Test', true);
    expect(items, hasLength(1));
    expect(items.first.title, 'Patch now & stay safe');
    expect(items.first.published, DateTime.utc(2026, 11, 27, 5, 0));
    expect(items.first.cyber, isTrue);
  });

  test('parses Atom entries', () {
    const atom = '''<feed xmlns="http://www.w3.org/2005/Atom">
      <entry><title>New chip</title><link rel="alternate" href="https://b.example/x"/><updated>2026-11-26T08:00:00Z</updated></entry>
    </feed>''';
    final items = NewsService.parseFeed(atom, 'Atom', false);
    expect(items.single.url, 'https://b.example/x');
    expect(items.single.published, DateTime.utc(2026, 11, 26, 8));
  });

  test('GMT dates parse', () {
    expect(NewsService.parseDate('Thu, 26 Nov 2026 23:15:00 GMT'), DateTime.utc(2026, 11, 26, 23, 15));
  });

  test('select keeps at most 5 cyber and 15 total, newest first, no duplicates', () {
    final base = DateTime.utc(2026, 11, 27);
    final all = [
      for (var i = 0; i < 9; i++) NewsItem('Cyber $i', 'https://c/$i', 'C', base.subtract(Duration(hours: i)), true),
      for (var i = 0; i < 20; i++) NewsItem('Tech $i', 'https://t/$i', 'T', base.subtract(Duration(hours: i)), false),
      NewsItem('cyber 0', 'https://dup', 'C', base, true),
    ];
    final picked = NewsService.select(all);
    expect(picked.length, 15);
    expect(picked.where((e) => e.cyber).length, 5);
    expect(picked.first.title, 'Cyber 0');
    expect(picked.map((e) => e.title.toLowerCase()).toSet().length, 15);
  });
}
