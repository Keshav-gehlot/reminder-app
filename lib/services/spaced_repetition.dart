/// Simple spaced repetition: each successful review grows the gap.
///
/// Grades: 'review' (again), 'ok' (good), 'easy'.
/// - again → back tomorrow, interval resets to 1 day
/// - good  → first time 3 days, then interval × 2
/// - easy  → first time 7 days, then interval × 3
/// Intervals are capped at 120 days.
Map<String, dynamic> scheduleReview(String grade, {int? previousInterval, DateTime? now}) {
  final at = now ?? DateTime.now();
  final prev = previousInterval ?? 0;
  int days;
  switch (grade) {
    case 'easy':
      days = prev <= 0 ? 7 : prev * 3;
      break;
    case 'ok':
      days = prev <= 0 ? 3 : prev * 2;
      break;
    default:
      days = 1;
  }
  if (days > 120) days = 120;
  final today = DateTime(at.year, at.month, at.day);
  final due = DateTime(today.year, today.month, today.day + days, 9);
  return {
    'confidence': grade,
    'interval': days,
    'reviewDue': due.toUtc().toIso8601String(),
    'lastReviewAt': at.toUtc().toIso8601String(),
  };
}

/// True when a solved topic's review date has arrived.
bool isReviewDue(Map<String, dynamic>? progress, {DateTime? now}) {
  if (progress == null || progress['done'] != true) return false;
  final due = DateTime.tryParse(progress['reviewDue']?.toString() ?? '');
  if (due == null) return progress['confidence'] == 'review';
  final n = now ?? DateTime.now();
  final endOfToday = DateTime(n.year, n.month, n.day, 23, 59, 59);
  return !due.toLocal().isAfter(endOfToday);
}

/// Human label such as "today", "tomorrow" or "in 6 days".
String reviewLabel(Map<String, dynamic>? progress, {DateTime? now}) {
  final due = DateTime.tryParse(progress?['reviewDue']?.toString() ?? '')?.toLocal();
  if (due == null) return '';
  final n = now ?? DateTime.now();
  final days = DateTime(due.year, due.month, due.day).difference(DateTime(n.year, n.month, n.day)).inDays;
  if (days <= 0) return 'today';
  if (days == 1) return 'tomorrow';
  return 'in $days days';
}
