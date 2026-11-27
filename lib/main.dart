import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/workspace_store.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'services/crash_log.dart';
import 'services/notification_service.dart';
import 'theme.dart';

const prefsUrlKey = 'cybertrack_supabase_url';
const prefsKeyKey = 'cybertrack_supabase_key';
const prefsSkipLoginKey = 'cybertrack_skip_login';

/// Default project for CyberTrack. The publishable key is entered once in the
/// app (or supplied at build time); the URL is prefilled for convenience.
const defaultSupabaseUrl = 'https://yfoqqokapqlvqibifizp.supabase.co';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CrashLog.install();
  try {
    await NotificationService.instance.initialize();
  } catch (e, st) {
    CrashLog.record('Notification init failed: $e', st);
  }
  runApp(const Root());
}

class _Boot {
  _Boot(this.store, this.client, this.skipLogin);
  final WorkspaceStore store;
  final SupabaseClient? client;
  final bool skipLogin;
}

/// Loads configuration and can reload it in place (e.g. after the user
/// connects cloud sync), so no app restart is needed.
class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  static bool _supabaseReady = false;
  late Future<_Boot> boot = _load();

  Future<_Boot> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final url = supabaseUrl.isNotEmpty ? supabaseUrl : (prefs.getString(prefsUrlKey) ?? defaultSupabaseUrl);
    final key = supabasePublishableKey.isNotEmpty ? supabasePublishableKey : (prefs.getString(prefsKeyKey) ?? '');
    SupabaseClient? client;
    final keyOk = key.startsWith('sb_publishable_') || key.startsWith('eyJ');
    if (url.startsWith('https://') && keyOk) {
      try {
        if (!_supabaseReady) {
          await Supabase.initialize(url: url, publishableKey: key);
          _supabaseReady = true;
        }
        client = Supabase.instance.client;
      } catch (e) {
        debugPrint('Supabase init failed: $e');
      }
    }
    final store = WorkspaceStore(client);
    await store.initialize();
    return _Boot(store, client, prefs.getBool(prefsSkipLoginKey) ?? false);
  }

  void reload() => setState(() => boot = _load());

  @override
  Widget build(BuildContext context) => FutureBuilder<_Boot>(
        future: boot,
        builder: (context, snap) {
          if (!snap.hasData) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildTheme(),
              home: const Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }
          final b = snap.data!;
          return CyberTrackApp(
            key: ObjectKey(b),
            store: b.store,
            client: b.client,
            skipLogin: b.skipLogin,
            onReload: reload,
          );
        },
      );
}

class CyberTrackApp extends StatefulWidget {
  const CyberTrackApp({
    super.key,
    required this.store,
    required this.client,
    required this.skipLogin,
    required this.onReload,
  });

  final WorkspaceStore store;
  final SupabaseClient? client;
  final bool skipLogin;
  final VoidCallback onReload;

  @override
  State<CyberTrackApp> createState() => _CyberTrackAppState();
}

class _CyberTrackAppState extends State<CyberTrackApp> with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSubscription;
  late bool skipLogin = widget.skipLogin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final client = widget.client;
    if (client != null) {
      _authSubscription = client.auth.onAuthStateChange.listen(
        (state) {
          final user = state.session?.user;
          if (user != null) {
            unawaited(widget.store.activateUser(user.id));
          } else if (widget.store.signedIn) {
            unawaited(widget.store.deactivateUser());
          }
          if (mounted) setState(() {});
        },
        onError: (Object error) => debugPrint('Auth listener: $error'),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(widget.store.syncNow());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    widget.store.dispose();
    super.dispose();
  }

  Future<void> setSkip(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsSkipLoginKey, value);
    if (mounted) setState(() => skipLogin = value);
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = widget.client?.auth.currentSession != null;
    final showAuth = !signedIn && !skipLogin;
    return MaterialApp(
      title: 'CyberTrack 12',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: showAuth
          ? LoginScreen(
              client: widget.client,
              onConnected: widget.onReload,
              onSkip: () => setSkip(true),
            )
          : AppShell(
              store: widget.store,
              client: widget.client,
              onSignedOut: () => setSkip(false),
              onReload: widget.onReload,
            ),
    );
  }
}
