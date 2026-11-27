import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/workspace_store.dart';
import '../services/accounts_service.dart';
import '../theme.dart';

const _tabular = [FontFeature.tabularFigures()];

String _ago(String? iso) {
  final d = DateTime.tryParse(iso ?? '');
  if (d == null) return '';
  final m = DateTime.now().toUtc().difference(d).inMinutes;
  if (m < 1) return 'just now';
  if (m < 60) return '${m}m ago';
  if (m < 60 * 24) return '${m ~/ 60}h ago';
  return '${m ~/ (60 * 24)}d ago';
}

/// All linked platform accounts. Handles and stats sync with the CyberTrack account.
class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key, required this.store, this.standalone = false});
  final WorkspaceStore store;
  final bool standalone;
  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final busy = <Platform>{};
  bool refreshingAll = false;

  void toast(String t) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> run(Platform p, Future<void> Function() job, {String? ok}) async {
    setState(() => busy.add(p));
    try {
      await job();
      if (ok != null) toast(ok);
    } catch (e) {
      toast(e.toString());
    } finally {
      if (mounted) setState(() => busy.remove(p));
    }
  }

  Future<void> refreshAll() async {
    setState(() => refreshingAll = true);
    var failed = 0;
    for (final p in Platform.values) {
      if (AccountsService.linked(widget.store, p) == null || platforms[p]!.manual) continue;
      setState(() => busy.add(p));
      try {
        await AccountsService.refresh(widget.store, p);
      } catch (_) {
        failed++;
      }
      if (mounted) setState(() => busy.remove(p));
    }
    if (mounted) setState(() => refreshingAll = false);
    toast(failed == 0 ? 'All accounts updated.' : '$failed account(s) could not be updated.');
  }

  Future<void> connect(Platform p) async {
    final info = platforms[p]!;
    final existing = AccountsService.linked(widget.store, p);
    final handle = TextEditingController(text: info.needsToken ? '' : existing?['handle']?.toString() ?? '');
    final score = TextEditingController(text: (existing?['headline'] ?? '').toString().replaceAll(',', ''));
    final solved = TextEditingController(text: ((existing?['stats'] as Map?)?['Solved'] ?? '').toString().replaceAll(',', ''));
    var obscure = true;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(info.icon, color: info.color),
              const SizedBox(width: 10),
              Text('Link ${info.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 8),
            Text(info.help, style: const TextStyle(color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 14),
            TextField(
              controller: handle,
              autofocus: true,
              obscureText: info.needsToken && obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: info.handleLabel,
                suffixIcon: info.needsToken
                    ? IconButton(
                        tooltip: obscure ? 'Show token' : 'Hide token',
                        icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => set(() => obscure = !obscure),
                      )
                    : null,
              ),
            ),
            if (info.manual) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: score, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Score'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: solved, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Challenges solved'))),
              ]),
            ],
            if (info.needsToken)
              TextButton.icon(
                onPressed: () => launchUrl(Uri.parse('https://app.hackthebox.com/account-settings'), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open HTB account settings'),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => Navigator.pop(ctx, handle.text.trim().isNotEmpty), child: Text(info.manual ? 'Save' : 'Link and sync')),
            ),
          ]),
        ),
      ),
    );
    final h = handle.text, sc = int.tryParse(score.text.trim()) ?? 0, so = int.tryParse(solved.text.trim()) ?? 0;
    handle.dispose();
    score.dispose();
    solved.dispose();
    if (ok != true) return;
    if (info.manual) {
      await run(p, () => AccountsService.saveManual(widget.store, p, h, sc, so), ok: '${info.name} saved.');
    } else {
      await run(p, () => AccountsService.link(widget.store, p, h), ok: '${info.name} linked.');
    }
  }

  Future<void> unlink(Platform p) async {
    final info = platforms[p]!;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Unlink ${info.name}?'),
        content: const Text('This removes the saved stats from all your devices. Your account on the platform is not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unlink')),
        ],
      ),
    );
    if (yes == true) await run(p, () => AccountsService.unlink(widget.store, p), ok: '${info.name} unlinked.');
  }

  @override
  Widget build(BuildContext context) {
    final body = AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final linkedCount = Platform.values.where((p) => AccountsService.linked(widget.store, p) != null).length;
        return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Expanded(
              child: Text(
                'Link your platform accounts. Usernames and stats sync to every device signed in to CyberTrack, and refresh automatically twice a day.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ),
            if (linkedCount > 0)
              refreshingAll
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(onPressed: refreshAll, tooltip: 'Refresh all', icon: const Icon(Icons.sync)),
          ]),
          if (widget.store.cloudConfigured == false)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Sign in to sync linked accounts across devices. Until then they stay on this phone.',
                  style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 12),
          for (final p in Platform.values) _AccountTile(
            platform: p,
            item: AccountsService.linked(widget.store, p),
            busy: busy.contains(p),
            onConnect: () => connect(p),
            onRefresh: () => run(p, () => AccountsService.refresh(widget.store, p), ok: '${platforms[p]!.name} updated.'),
            onUnlink: () => unlink(p),
          ),
        ]);
      },
    );
    if (!widget.standalone) return body;
    return Scaffold(appBar: AppBar(title: const Text('Linked accounts')), body: body);
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.platform,
    required this.item,
    required this.busy,
    required this.onConnect,
    required this.onRefresh,
    required this.onUnlink,
  });
  final Platform platform;
  final Map<String, dynamic>? item;
  final bool busy;
  final VoidCallback onConnect, onRefresh, onUnlink;

  @override
  Widget build(BuildContext context) {
    final info = platforms[platform]!;
    final linked = item != null;
    final stats = Map<String, dynamic>.from((item?['stats'] as Map?) ?? const {});
    final display = (item?['display'] ?? item?['handle'] ?? '').toString();
    final handle = (item?['handle'] ?? '').toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 20, backgroundColor: info.color.withValues(alpha: 0.12), child: Icon(info.icon, color: info.color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(info.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(
                  linked ? '$display · ${_ago(item!['fetchedAt']?.toString())}' : (info.manual ? 'No API · manual entry' : 'Not linked'),
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
            if (linked)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(item!['headline']?.toString() ?? '—',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: info.color, fontFeatures: _tabular)),
                Text(item!['headlineLabel']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ]),
            if (busy)
              const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            else if (!linked)
              Padding(padding: const EdgeInsets.only(right: 6), child: FilledButton.tonal(onPressed: onConnect, child: const Text('Link')))
            else
              PopupMenuButton<String>(
                tooltip: 'More',
                onSelected: (v) {
                  if (v == 'refresh') onRefresh();
                  if (v == 'edit') onConnect();
                  if (v == 'open') launchUrl(Uri.parse(info.profileUrl(handle)), mode: LaunchMode.externalApplication);
                  if (v == 'unlink') onUnlink();
                },
                itemBuilder: (_) => [
                  if (!info.manual) const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
                  PopupMenuItem(value: 'edit', child: Text(info.manual ? 'Update score' : (info.needsToken ? 'Replace token' : 'Change username'))),
                  const PopupMenuItem(value: 'open', child: Text('Open profile')),
                  const PopupMenuItem(value: 'unlink', child: Text('Unlink')),
                ],
              ),
          ]),
          if (linked && stats.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in stats.entries)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '${e.key} ', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    TextSpan(text: '${e.value}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, fontFeatures: _tabular)),
                  ])),
                ),
            ]),
          ],
        ]),
      ),
    );
  }
}

/// Compact row of linked accounts for the Practice log.
class LinkedAccountsSummary extends StatelessWidget {
  const LinkedAccountsSummary({super.key, required this.store, required this.onManage});
  final WorkspaceStore store;
  final VoidCallback onManage;
  @override
  Widget build(BuildContext context) {
    final linked = [for (final p in Platform.values) if (AccountsService.linked(store, p) != null) p];
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onManage,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(children: [
            const Icon(Icons.link, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: linked.isEmpty
                  ? const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Link your accounts', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text('LeetCode, TryHackMe, HTB, picoCTF, CTFtime, Codeforces, GitHub', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    ])
                  : Wrap(spacing: 14, runSpacing: 6, children: [
                      for (final p in linked)
                        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Text(AccountsService.linked(store, p)!['headline']?.toString() ?? '—',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: platforms[p]!.color, fontFeatures: _tabular)),
                          Text(platforms[p]!.name, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        ]),
                    ]),
            ),
            const Icon(Icons.chevron_right),
          ]),
        ),
      ),
    );
  }
}
