import 'package:cybertrack12/services/accounts_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('handles accept usernames, @names and profile URLs', () {
    expect(normalizeHandle(Platform.github, 'https://github.com/Keshav-gehlot/'), 'Keshav-gehlot');
    expect(normalizeHandle(Platform.leetcode, ' @keshav '), 'keshav');
    expect(normalizeHandle(Platform.tryhackme, 'https://tryhackme.com/p/greedpanda?tab=rooms'), 'greedpanda');
    expect(normalizeHandle(Platform.ctftime, 'https://ctftime.org/team/12345/'), '12345');
    expect(normalizeHandle(Platform.hackthebox, ' abc/def.token '), 'abc/def.token');
  });

  test('LeetCode', () {
    final s = AccountParsers.leetcode('k', {
      'data': {
        'matchedUser': {
          'profile': {'ranking': 123456},
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
    })!;
    expect(s.headline, '60');
    expect(s.stats['Medium'], '25');
    expect(s.stats['Ranking'], '123,456');
    expect(AccountParsers.leetcode('x', {'data': {'matchedUser': null}}), isNull);
  });

  test('TryHackMe public profile', () {
    final s = AccountParsers.tryhackme('greedpanda', {
      'status': 'success',
      'data': {
        'username': 'greedpanda',
        'level': 13,
        'totalPoints': 30406,
        'badgesNumber': 25,
        'completedRoomsNumber': 207,
        'streak': 0,
        'rank': 15220,
        'topPercentage': 1,
        'isPrivateProfile': false,
      }
    })!;
    expect(s.headline, '207');
    expect(s.stats['Rank'], '15,220');
    expect(s.stats['Top'], '1%');
    expect(() => AccountParsers.tryhackme('p', {'status': 'success', 'data': {'isPrivateProfile': true}}), throwsA(isA<String>()));
    expect(AccountParsers.tryhackme('x', {'status': 'error'}), isNull);
  });

  test('Hack The Box basic profile', () {
    final s = AccountParsers.hackthebox({
      'profile': {'name': 'keshav', 'rank': 'Hacker', 'ranking': 4321, 'points': 80, 'system_owns': 12, 'user_owns': 15, 'respects': 3}
    })!;
    expect(s.headline, '27');
    expect(s.stats['Global'], '#4,321');
    expect(s.stats['Rank'], 'Hacker');
  });

  test('CTFtime team rating', () {
    final s = AccountParsers.ctftime('999', {
      'name': 'SRM Hackers',
      'rating': {
        '2026': {'rating_place': 412, 'rating_points': 58.731, 'country_place': 9},
        '2025': {'rating_place': 800},
      }
    }, year: 2026)!;
    expect(s.handle, 'SRM Hackers');
    expect(s.headline, '#412');
    expect(s.stats['Points 2026'], '58.7');
    expect(s.stats['Place 2025'], '#800');
  });

  test('Codeforces and GitHub', () {
    final cf = AccountParsers.codeforces({
      'status': 'OK',
      'result': [
        {'handle': 'tourist', 'rating': 3500, 'maxRating': 4000, 'rank': 'legendary grandmaster', 'maxRank': 'tourist'}
      ]
    })!;
    expect(cf.headline, '3,500');
    expect(AccountParsers.codeforces({'status': 'FAILED'}), isNull);
    final gh = AccountParsers.github({'login': 'Keshav-gehlot', 'public_repos': 42, 'followers': 7, 'following': 3, 'public_gists': 0})!;
    expect(gh.headline, '42');
    expect(gh.stats['Followers'], '7');
  });
}
