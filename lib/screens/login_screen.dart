import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' show LaunchMode;

import '../theme.dart';
import 'sync_setup_screen.dart';

/// First screen on a fresh install: sign in with Google or an email code,
/// or continue without an account. Works even before cloud is connected:
/// the sign-in buttons then ask for the project key once and continue.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.client, required this.onConnected, required this.onSkip});
  final SupabaseClient? client;
  final VoidCallback onConnected;
  final VoidCallback onSkip;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const redirect = 'com.keshavgehlot.cybertrack12://login-callback';
  final email = TextEditingController();
  final code = TextEditingController();
  bool showEmail = false, sent = false, busy = false;

  @override
  void dispose() {
    email.dispose();
    code.dispose();
    super.dispose();
  }

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Returns the client, asking the user to connect cloud sync first if needed.
  Future<SupabaseClient?> ensureClient() async {
    if (widget.client != null) return widget.client;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SyncSetupScreen(firstRun: true)),
    );
    if (saved == true) widget.onConnected();
    return null;
  }

  Future<void> google() async {
    final client = await ensureClient();
    if (client == null) return;
    setState(() => busy = true);
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirect,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } on AuthException catch (e) {
      message(e.message.contains('provider is not enabled')
          ? 'Google sign-in is not enabled for this project yet. Use the email code for now.'
          : 'Google sign-in failed: ${e.message}');
    } catch (e) {
      message('Google sign-in failed: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> sendCode() async {
    final client = await ensureClient();
    if (client == null) return;
    final address = email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(address)) {
      message('Enter a valid email address.');
      return;
    }
    setState(() => busy = true);
    try {
      await client.auth.signInWithOtp(email: address);
      if (mounted) setState(() => sent = true);
      message('We sent a 6-digit code to $address.');
    } catch (e) {
      message('Could not send the code: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> verify() async {
    final client = widget.client;
    if (client == null) return;
    final token = code.text.replaceAll(RegExp(r'\s'), '');
    if (token.length < 6) {
      message('Enter the 6-digit code from your email.');
      return;
    }
    setState(() => busy = true);
    try {
      await client.auth.verifyOTP(type: OtpType.email, email: email.text.trim(), token: token);
    } catch (e) {
      message('That code did not work. Check it or request a new one.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.track_changes, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Welcome to CyberTrack',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                const Text(
                  'Learn DSA and CTF step by step, plan your week, and track your research. Sign in to keep everything in sync across your phones.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.5, fontSize: 15),
                ),
                const SizedBox(height: 28),
                const _Benefit(Icons.play_lesson, 'Lessons with diagrams, videos and hints'),
                const _Benefit(Icons.science_outlined, 'HTB, TryHackMe and picoCTF labs per topic'),
                const _Benefit(Icons.sync, 'Progress synced on every device'),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: busy ? null : google,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
                  icon: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Text('G', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
                  ),
                  label: const Text('Continue with Google'),
                ),
                const SizedBox(height: 10),
                if (!showEmail)
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => setState(() => showEmail = true),
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Continue with email'),
                  )
                else ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: email,
                    enabled: !sent,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline)),
                  ),
                  if (sent) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: code,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      maxLength: 8,
                      decoration: const InputDecoration(labelText: '6-digit code', prefixIcon: Icon(Icons.password), counterText: ''),
                    ),
                  ],
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: busy ? null : (sent ? verify : sendCode),
                    child: busy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(sent ? 'Verify and sign in' : 'Send me a code'),
                  ),
                  if (sent)
                    TextButton(
                      onPressed: busy ? null : () => setState(() => sent = false),
                      child: const Text('Use a different email or resend'),
                    ),
                ],
                const SizedBox(height: 18),
                TextButton(
                  onPressed: busy ? null : widget.onSkip,
                  child: const Text('Continue without an account', style: TextStyle(color: AppColors.muted)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Without an account your data stays on this phone. You can sign in later from the account menu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}
