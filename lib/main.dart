import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/workspace_store.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';

const prefsUrlKey = 'cybertrack_supabase_url';
const prefsKeyKey = 'cybertrack_supabase_key';
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();

  // Build-time values win; otherwise use values saved from inside the app.
  final prefs = await SharedPreferences.getInstance();
  final url = supabaseUrl.isNotEmpty
      ? supabaseUrl
      : (prefs.getString(prefsUrlKey) ?? '');
  final key = supabasePublishableKey.isNotEmpty
      ? supabasePublishableKey
      : (prefs.getString(prefsKeyKey) ?? '');

  SupabaseClient? client;
  final keyConfigured =
      key.startsWith('sb_publishable_') || key.startsWith('eyJ');
  if (url.startsWith('https://') && keyConfigured) {
    await Supabase.initialize(url: url, publishableKey: key);
    client = Supabase.instance.client;
  }

  final store = WorkspaceStore(client);
  await store.initialize();
  runApp(CyberTrackApp(store: store, client: client));
}

class CyberTrackApp extends StatefulWidget {
  const CyberTrackApp({
    super.key,
    required this.store,
    required this.client,
  });

  final WorkspaceStore store;
  final SupabaseClient? client;

  @override
  State<CyberTrackApp> createState() => _CyberTrackAppState();
}

class _CyberTrackAppState extends State<CyberTrackApp>
    with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSubscription;

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
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.store.syncNow());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    widget.store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needsLogin =
        widget.client != null && widget.client!.auth.currentSession == null;

    return MaterialApp(
      title: 'CyberTrack 12',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F5FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7665D8),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F5FA),
          foregroundColor: Color(0xFF24213A),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      home: needsLogin
          ? LoginScreen(client: widget.client!)
          : AppShell(store: widget.store, client: widget.client),
    );
  }
}
