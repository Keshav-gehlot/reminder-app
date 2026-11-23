import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart' show prefsUrlKey, prefsKeyKey, defaultSupabaseUrl;
import '../theme.dart';

/// Connect the app to Supabase once per device. Only the project URL and the
/// publishable key belong here, never the service-role key.
/// Pops with `true` when saved so the caller can reload the app.
class SyncSetupScreen extends StatefulWidget {
  const SyncSetupScreen({super.key, this.firstRun = false});
  final bool firstRun;

  @override
  State<SyncSetupScreen> createState() => _SyncSetupScreenState();
}

class _SyncSetupScreenState extends State<SyncSetupScreen> {
  final url = TextEditingController(text: defaultSupabaseUrl);
  final key = TextEditingController();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      final savedUrl = p.getString(prefsUrlKey);
      if (savedUrl != null && savedUrl.isNotEmpty) url.text = savedUrl;
      key.text = p.getString(prefsKeyKey) ?? '';
    });
  }

  @override
  void dispose() {
    url.dispose();
    key.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final u = url.text.trim().replaceAll(RegExp(r'/+$'), '');
    final k = key.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (!u.startsWith('https://')) {
      messenger.showSnackBar(const SnackBar(content: Text('The project URL must start with https://')));
      return;
    }
    if (k.contains('service_role') || k.startsWith('sb_secret_')) {
      messenger.showSnackBar(const SnackBar(content: Text('That is a secret key. Use the publishable key instead.')));
      return;
    }
    if (!(k.startsWith('sb_publishable_') || k.startsWith('eyJ'))) {
      messenger.showSnackBar(const SnackBar(content: Text('Paste the key that starts with sb_publishable_')));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsUrlKey, u);
    await prefs.setString(prefsKeyKey, k);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect cloud sync')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(
          widget.firstRun
              ? 'One-time setup so you can sign in. You only do this once per phone.'
              : 'Use the same values on every phone you want to sync.',
          style: const TextStyle(height: 1.5, fontSize: 15),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
          child: const Text(
            'Where to find these: Supabase dashboard → your project → Settings → API Keys. Copy the "Publishable key".',
            style: TextStyle(height: 1.45),
          ),
        ),
        const SizedBox(height: 18),
        TextField(controller: url, autocorrect: false, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Project URL')),
        const SizedBox(height: 12),
        TextField(controller: key, autocorrect: false, decoration: const InputDecoration(labelText: 'Publishable key', hintText: 'sb_publishable_…')),
        const SizedBox(height: 20),
        FilledButton(onPressed: save, child: const Text('Save and continue')),
      ]),
    );
  }
}
