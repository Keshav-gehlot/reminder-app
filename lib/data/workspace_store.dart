import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/notification_service.dart';

const _seedTime = '2026-11-23T00:00:00.000Z';

String projectKey(String name) {
  switch (name) {
    case 'LeakTrace + ECDAT':
      return 'leaktrace-ecd-at';
    case 'CROSSWITNESS':
      return 'crosswitness';
    case 'Network Attack Forecasting':
      return 'network-attack-forecasting';
    default:
      return 'bluetooth-music-middleware';
  }
}

String newWorkspaceId() =>
    DateTime.now().microsecondsSinceEpoch.toString() +
    '-' +
    DateTime.now().millisecondsSinceEpoch.toString();

DateTime? parseWorkspaceDate(dynamic value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}

class WorkspaceStore extends ChangeNotifier {
  WorkspaceStore(this.client);

  final SupabaseClient? client;
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final List<Map<String, dynamic>> _items = [];

  RealtimeChannel? _channel;
  String? _userId;
  bool syncing = false;
  bool _syncRequested = false;
  String? syncError;
  DateTime? lastSyncedAt;

  bool get cloudConfigured => client != null;
  bool get signedIn => _userId != null;

  List<Map<String, dynamic>> get items =>
      _items.where((item) => item['deleted'] != true).toList();

  List<Map<String, dynamic>> ofKind(String kind) =>
      items.where((item) => item['kind'] == kind).toList();

  List<Map<String, dynamic>> ofWeek(int week) =>
      items.where((item) => item['kind'] == 'task' && item['week'] == week).toList();

  Future<void> initialize() async {
    final raw = await _preferences.getString('cybertrack.workspace.guest');
    if (raw == null) {
      _items
        ..clear()
        ..addAll(seedWorkspace());
      await _persist();
    } else {
      _replace(_decode(raw));
    }

    final current = client?.auth.currentSession?.user.id;
    if (current != null) {
      await activateUser(current);
    }
    await NotificationService.instance.rescheduleAll(items);
    notifyListeners();
  }

  Future<void> activateUser(String userId) async {
    if (client == null || _userId == userId) return;
    await _channel?.unsubscribe();
    _userId = userId;

    final cached = await _preferences.getString(_cacheKey);
    if (cached != null) {
      _replace(mergeItems(_items, _decode(cached)));
    }
    await _persist();
    await syncNow();

    _channel = client!
        .channel('cybertrack-workspace-' + userId)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'workspaces',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final next = payload.newRecord['items'];
            if (next is List) {
              final remote = next
                  .whereType<Map>()
                  .map((entry) => Map<String, dynamic>.from(entry))
                  .toList();
              final merged = mergeItems(_items, remote);
              final hasChanged =
                  jsonEncode(normalizeItems(merged)) !=
                      jsonEncode(normalizeItems(_items));
              if (hasChanged) {
                _replace(merged);
                _persist();
                NotificationService.instance.rescheduleAll(items);
                notifyListeners();
              }
              if (jsonEncode(normalizeItems(merged)) !=
                  jsonEncode(normalizeItems(remote))) {
                syncNow();
              }
            }
          },
        )
        .subscribe();

    await NotificationService.instance.rescheduleAll(items);
    notifyListeners();
  }

  Future<void> deactivateUser() async {
    await _channel?.unsubscribe();
    _channel = null;
    await _persist();
    _userId = null;

    final guest = await _preferences.getString('cybertrack.workspace.guest');
    if (guest == null) {
      _replace(seedWorkspace());
      await _persist();
    } else {
      _replace(_decode(guest));
    }
    syncError = null;
    notifyListeners();
  }

  String get _cacheKey =>
      'cybertrack.workspace.' + (_userId ?? 'guest');

  List<Map<String, dynamic>> _decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  List<Map<String, dynamic>> normalizeItems(
      List<Map<String, dynamic>> values) {
    final normalized = values.map((item) => Map<String, dynamic>.from(item)).toList();
    normalized.sort((a, b) =>
        (a['id']?.toString() ?? '').compareTo(b['id']?.toString() ?? ''));
    return normalized;
  }

  List<Map<String, dynamic>> mergeItems(
    List<Map<String, dynamic>> local,
    List<Map<String, dynamic>> remote,
  ) {
    final byId = <String, Map<String, dynamic>>{};
    for (final item in [...local, ...remote]) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final previous = byId[id];
      final incomingTime =
          parseWorkspaceDate(item['updatedAt']) ?? DateTime.utc(1970);
      final previousTime = previous == null
          ? DateTime.utc(1970)
          : parseWorkspaceDate(previous['updatedAt']) ?? DateTime.utc(1970);
      if (previous == null || !incomingTime.isBefore(previousTime)) {
        byId[id] = Map<String, dynamic>.from(item);
      }
    }
    return normalizeItems(byId.values.toList());
  }

  void _replace(List<Map<String, dynamic>> next) {
    _items
      ..clear()
      ..addAll(next);
  }

  Future<void> _persist() async {
    await _preferences.setString(_cacheKey, jsonEncode(_items));
  }

  Future<void> upsert(Map<String, dynamic> source) async {
    final item = Map<String, dynamic>.from(source);
    item['updatedAt'] = DateTime.now().toUtc().toIso8601String();
    if ((item['id']?.toString() ?? '').isEmpty) {
      item['id'] = newWorkspaceId();
    }

    final index = _items.indexWhere((entry) => entry['id'] == item['id']);
    if (index == -1) {
      _items.add(item);
    } else {
      _items[index] = item;
    }

    await _persist();
    if (item['kind'] == 'reminder') {
      if (item['done'] == true || item['deleted'] == true) {
        await NotificationService.instance.cancel(item);
      } else {
        await NotificationService.instance.schedule(item);
      }
    }
    notifyListeners();
    await syncNow();
  }

  Future<void> update(
      Map<String, dynamic> item, Map<String, dynamic> changes) async {
    await upsert({...item, ...changes});
  }

  Future<void> remove(Map<String, dynamic> item) async {
    await update(item, {'deleted': true});
  }

  Future<void> syncNow() async {
    if (client == null || _userId == null) return;
    if (syncing) {
      _syncRequested = true;
      return;
    }

    syncing = true;
    syncError = null;
    notifyListeners();

    try {
      do {
        _syncRequested = false;
        final response = await client!.rpc(
          'sync_workspace',
          params: {'p_items': _items},
        );
        if (response is List) {
          final remote = response
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList();
          _replace(mergeItems(_items, remote));
          await _persist();
          await NotificationService.instance.rescheduleAll(items);
        }
        lastSyncedAt = DateTime.now();
      } while (_syncRequested && _userId != null);
    } catch (error) {
      syncError = error.toString();
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

List<Map<String, dynamic>> seedWorkspace() {
  const projects = <String, String>{
    'LeakTrace + ECDAT':
        'Cryptographic inventory, evidence durability, leak attribution and renewal.',
    'CROSSWITNESS':
        'Digital forensics research proposal, methodology, architecture and validation.',
    'Network Attack Forecasting':
        'Dataset selection, attack-campaign representation and evaluation.',
    'Bluetooth Music Middleware':
        'Communication, synchronization, latency and performance optimization.',
  };

  final result = <Map<String, dynamic>>[];
  for (var week = 1; week <= 12; week++) {
    final phase = week <= 3
        ? 'Foundation'
        : week <= 6
            ? 'Development'
            : week <= 9
                ? 'Implementation and validation'
                : 'Consolidation';

    result.addAll([
      {
        'id': 'task-w' + week.toString() + '-leetcode',
        'kind': 'task',
        'category': 'LeetCode',
        'week': week,
        'title': 'Solve 1–2 DSA problems',
        'detail': 'Practice the current pattern and analyze complexity.',
        'done': false,
        'updatedAt': _seedTime,
      },
      {
        'id': 'task-w' + week.toString() + '-timed-coding',
        'kind': 'task',
        'category': 'LeetCode',
        'week': week,
        'title': 'Timed coding practice',
        'detail': 'Mock OA, contest or revision of failed problems.',
        'done': false,
        'updatedAt': _seedTime,
      },
      {
        'id': 'task-w' + week.toString() + '-individual-ctf',
        'kind': 'task',
        'category': 'CTF',
        'week': week,
        'title': 'Individual CTF practice',
        'detail': 'Solve challenges and write down the methodology.',
        'done': false,
        'updatedAt': _seedTime,
      },
      {
        'id': 'task-w' + week.toString() + '-team-ctf',
        'kind': 'task',
        'category': 'CTF',
        'week': week,
        'title': 'Team CTF preparation',
        'detail': 'Coordinate with teammates or take part in a live event.',
        'done': false,
        'updatedAt': _seedTime,
      },
      ...projects.entries.map((entry) => {
            'id': 'task-w' +
                week.toString() +
                '-research-' +
                projectKey(entry.key),
            'kind': 'task',
            'category': 'Research',
            'project': entry.key,
            'week': week,
            'title': phase + ' milestone: ' + entry.key,
            'detail': entry.value,
            'done': false,
            'updatedAt': _seedTime,
          }),
      {
        'id': 'task-w' + week.toString() + '-weekly-review',
        'kind': 'task',
        'category': 'Planning',
        'week': week,
        'title': 'Weekly review and references',
        'detail': 'Review progress and plan the next week.',
        'done': false,
        'updatedAt': _seedTime,
      },
    ]);
  }

  for (final entry in projects.entries) {
    result.add({
      'id': 'project-' + projectKey(entry.key),
      'kind': 'project',
      'title': entry.key,
      'detail': entry.value,
      'updatedAt': _seedTime,
    });
  }
  return result;
}
