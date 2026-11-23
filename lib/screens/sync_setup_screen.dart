import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart' show prefsUrlKey, prefsKeyKey;

/// Lets the user connect their own Supabase project from inside the app.
/// Only the project URL and the *publishable* key belong here - never the
/// service-role key.
class SyncSetupScreen extends StatefulWidget {
  const SyncSetupScreen({super.key});

  @override
  State<SyncSetupScreen> createState() => _SyncSetupScreenState();
}

class _SyncSetupScreenState extends State<SyncSetupScreen> {
  final url = TextEditingController();
  final key = TextEditingController();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      url.text = p.getString(prefsUrlKey) ?? '';
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
    if (!u.startsWith('https://') ||
        !(k.startsWith('sb_publishable_') || k.startsWith('eyJ'))) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Enter https://<project>.supabase.co and a publishable key.')));
      return;
    }
    if (k.contains('service_role')) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Do not use a service-role key in the app.')));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsUrlKey, u);
    await prefs.setString(prefsKeyKey, k);
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(
        content: Text('Saved. Fully close and reopen CyberTrack to sign in.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud sync setup')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text(
          'Paste your Supabase project URL and publishable key (Supabase dashboard > Settings > API Keys). Use the same values on every device.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: url,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'Project URL'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: key,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'Publishable key'),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: save, child: const Text('Save')),
      ]),
    );
  }
}
