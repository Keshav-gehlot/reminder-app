import 'package:cybertrack12/data/lessons.dart';
import 'package:cybertrack12/data/quizzes.dart';
import 'package:cybertrack12/services/leetcode_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every lesson has a 3-question quiz with valid answers', () {
    for (final l in lessons) {
      final q = quizzes[l.title];
      expect(q, isNotNull, reason: 'missing quiz for ${l.title}');
      expect(q!.length, 3, reason: l.title);
      for (final item in q) {
        expect(item.answer, inInclusiveRange(0, item.options.length - 1), reason: item.q);
        expect(item.options.toSet().length, item.options.length, reason: 'duplicate option in ${item.q}');
      }
    }
    expect(quizzes.length, lessons.length);
  });

  test('lesson ids are unique and every lesson has an 11-char video id', () {
    expect(lessons.map((l) => l.id).toSet().length, lessons.length);
    for (final l in lessons) {
      expect(l.videoId.length, 11, reason: l.title);
    }
  });

  test('every CTF lesson maps to exams and has labs', () {
    for (final l in lessons.where((l) => l.area == 'CTF')) {
      expect(l.exam, isNotEmpty, reason: l.title);
      expect(l.practice.length, greaterThanOrEqualTo(2), reason: l.title);
      for (final p in l.practice) {
        expect(p.url, startsWith('https://'), reason: p.title);
      }
    }
  });

  test('new CTF topics are present', () {
    final titles = lessons.map((l) => l.title).toSet();
    for (final t in ['Binary exploitation basics', 'OSINT investigations', 'Steganography', 'Active Directory basics']) {
      expect(titles, contains(t));
    }
  });

  test('LeetCode GraphQL response parsing', () {
    final s = LeetCodeStats.fromGraphQL('keshav', {
      'data': {
        'matchedUser': {
          'submitStatsGlobal': {
            'acSubmissionNum': [
              {'difficulty': 'All', 'count': 60},
              {'difficulty': 'Easy', 'count': 30},
              {'difficulty': 'Medium', 'count': 25},
              {'difficulty': 'Hard', 'count': 5},
            ]
          }
        }
      }
    });
    expect(s!.total, 60);
    expect(s.medium, 25);
    expect(LeetCodeStats.fromGraphQL('nobody', {'data': {'matchedUser': null}}), isNull);
  });
}
