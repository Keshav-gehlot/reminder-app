import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.client});
  final SupabaseClient client;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final code = TextEditingController();
  bool sent = false;
  bool busy = false;

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

  Future<void> sendCode() async {
    final address = email.text.trim();
    if (!address.contains('@')) {
      message('Enter a valid email address.');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.client.auth.signInWithOtp(email: address);
      if (mounted) {
        setState(() => sent = true);
        message('Check your email for the verification code.');
      }
    } catch (error) {
      message('Could not send the email code: ' + error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> verifyCode() async {
    if (code.text.trim().isEmpty) {
      message('Enter the verification code from your email.');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.client.auth.verifyOTP(
        type: OtpType.email,
        email: email.text.trim(),
        token: code.text.trim(),
      );
    } catch (error) {
      message('Verification failed: ' + error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7665D8);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: purple,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.track_changes,
                        color: Colors.white, size: 29),
                  ),
                  const SizedBox(height: 30),
                  const Text('Your work, synced.',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with the same email on every Android device to share reminders, CTF practice, LeetCode progress and research notes.',
                    style: TextStyle(
                        color: Colors.grey.shade700, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  if (sent) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: code,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Email verification code',
                        prefixIcon: Icon(Icons.password),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: busy ? null : (sent ? verifyCode : sendCode),
                      child: Text(busy
                          ? 'Please wait…'
                          : (sent ? 'Verify and sign in' : 'Send email code')),
                    ),
                  ),
                  if (sent)
                    TextButton(
                      onPressed: busy ? null : sendCode,
                      child: const Text('Send another code'),
                    ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEAFB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Your account data is isolated with row-level database security. Use the same verified email to connect your devices.',
                      style: TextStyle(
                          color: Color(0xFF4C426F),
                          fontSize: 11,
                          height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
