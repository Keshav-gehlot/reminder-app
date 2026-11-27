import 'package:cybertrack12/services/spaced_repetition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 27, 18);

  test('first ratings set 1, 3 and 7 day gaps', () {
    expect(scheduleReview('review', now: now)['interval'], 1);
    expect(scheduleReview('ok', now: now)['interval'], 3);
    expect(scheduleReview('easy', now: now)['interval'], 7);
  });

  test('successful reviews grow the interval and cap at 120', () {
    expect(scheduleReview('ok', previousInterval: 3, now: now)['interval'], 6);
    expect(scheduleReview('easy', previousInterval: 7, now: now)['interval'], 21);
    expect(scheduleReview('easy', previousInterval: 90, now: now)['interval'], 120);
  });

  test('again resets to one day', () {
    expect(scheduleReview('review', previousInterval: 30, now: now)['interval'], 1);
  });

  test('due date is the morning N days later', () {
    final due = DateTime.parse(scheduleReview('ok', now: now)['reviewDue']).toLocal();
    expect(DateTime(due.year, due.month, due.day), DateTime(2026, 11, 30));
  });

  test('isReviewDue only for solved topics whose date has come', () {
    final p = {'done': true, ...scheduleReview('ok', now: now)};
    expect(isReviewDue(p, now: now), isFalse);
    expect(isReviewDue(p, now: DateTime(2026, 11, 30, 8)), isTrue);
    expect(isReviewDue({'done': false, ...p}..['done'] = false, now: DateTime(2027)), isFalse);
    expect(isReviewDue(null, now: now), isFalse);
  });

  test('legacy review flag without a date counts as due', () {
    expect(isReviewDue({'done': true, 'confidence': 'review'}, now: now), isTrue);
    expect(isReviewDue({'done': true, 'confidence': 'easy'}, now: now), isFalse);
  });

  test('labels', () {
    final p = scheduleReview('review', now: now);
    expect(reviewLabel(p, now: now), 'tomorrow');
    expect(reviewLabel(scheduleReview('easy', now: now), now: now), 'in 7 days');
  });
}
