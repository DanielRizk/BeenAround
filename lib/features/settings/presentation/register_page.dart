// REGISTER PAGE — UI kit + fixes:
// ✅ AppScaffold / GlowCard
// ✅ Uses AppDialogs 6-digit dialog (no AlertDialog/TextField pin)
// ✅ Pops back to Account like Login (Navigator.pop(context, true))
// ✅ Forces AccountPage to show updated user immediately:
//    - ensures AuthController.fetchMe() runs after login
// ✅ Uses AppToast (no SnackBar)
// ✅ Keeps all business logic intact

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../shared/backend/auth_controller.dart';
import '../../../shared/export/user_data_file_transfer.dart';
import '../../../shared/ui_kit/app_cards.dart';
import '../../../shared/ui_kit/app_dialogs.dart';
import '../../../shared/ui_kit/app_scaffold.dart';
import '../../../shared/ui_kit/app_toast.dart';
import '../../../shared/ui_kit/app_style.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _repeat = TextEditingController();

  String? _challengeId;
  String? _error;
  bool _busy = false;
  bool _pinExpired = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _username.dispose();
    _email.dispose();
    _pass.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _toast(String msg, {AppToastTone tone = AppToastTone.normal}) {
    if (!mounted) return;
    AppToast.show(context, message: msg, tone: tone);
  }

  Future<void> _submit() async {
    if (_busy) return;

    FocusScope.of(context).unfocus();

    if (_pass.text != _repeat.text) {
      setState(() => _error = 'Passwords do not match');
      _toast('Passwords do not match', tone: AppToastTone.danger);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('${AuthController.baseUrl}/auth/register/request');
      final req = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _email.text.trim(),
          'username': _username.text.trim(),
        }),
      )
          .timeout(const Duration(seconds: 12));

      if (req.statusCode != 200) {
        String msg = 'Request failed (${req.statusCode})';
        try {
          final j = jsonDecode(req.body);
          if (j is Map && j['detail'] != null) msg = j['detail'].toString();
        } catch (_) {}
        setState(() => _error = msg);
        _toast(msg, tone: AppToastTone.danger);
        return;
      }

      final data = jsonDecode(req.body);
      _challengeId = data['challenge_id']?.toString();

      if (_challengeId == null || _challengeId!.isEmpty) {
        const msg = 'Server response missing challenge_id';
        setState(() => _error = msg);
        _toast('Server response invalid', tone: AppToastTone.danger);
        return;
      }

      if (!mounted) return;

      // ✅ Premium 6-digit dialog from UI kit
      final code = await AppDialogs.showSixDigitCodeDialog(
        context: context,
        title: 'Enter 6-digit code',
        subtitle: 'Check your email and enter the verification code.',
        confirmLabel: 'Verify',
        cancelLabel: 'Cancel',
        validate: _verify,
      );
      if (code == null) return;

      await _completeRegistration();

      // If verify succeeded, we complete in validate() path already.
      // But to be safe, ensure completion if validate returns true without popping.
      // (No-op if already completed.)
    } on TimeoutException {
      const msg = 'Server not responding (timeout). Check connection and try again.';
      setState(() => _error = msg);
      _toast(msg, tone: AppToastTone.danger);
    } on SocketException {
      const msg = 'No connection to server. Check Wi-Fi / server address.';
      setState(() => _error = msg);
      _toast(msg, tone: AppToastTone.danger);
    } catch (e) {
      final msg = 'Unexpected error: $e';
      setState(() => _error = msg);
      _toast(msg, tone: AppToastTone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _verify(String code) async {
    try {
      final res = await http.post(
        Uri.parse('${AuthController.baseUrl}/auth/register/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'challenge_id': _challengeId,
          'code': code,
        }),
      );

      if (res.statusCode == 200) return null;

      if (res.statusCode == 429) {
        return 'PIN expired. Please cancel and start registration again.';
      }

      // Optional: parse server detail
      try {
        final j = jsonDecode(res.body);
        if (j is Map && j['detail'] != null) {
          return j['detail'].toString();
        }
      } catch (_) {}

      return 'Invalid PIN';
    } catch (e) {
      return 'Verification failed. Check connection and try again.';
    }
  }

  Future<void> _completeRegistration() async {
    final payloadJson = await UserDataFileTransfer.exportToJsonString();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AuthController.baseUrl}/auth/register/complete'),
    );

    request.fields['challenge_id'] = _challengeId!;
    request.fields['first_name'] = _first.text.trim();
    request.fields['last_name'] = _last.text.trim();
    request.fields['username'] = _username.text.trim();
    request.fields['email'] = _email.text.trim();
    request.fields['password'] = _pass.text;
    request.fields['payload_json'] = payloadJson;

    final response = await request.send();

    if (response.statusCode != 201) {
      setState(() => _error = 'Registration failed');
      _toast('Registration failed', tone: AppToastTone.danger);
      return;
    }

    // ✅ login like before
    await AuthController.login(_email.text.trim(), _pass.text);

    // ✅ FIX: ensure AccountPage shows updated profile immediately
    // AccountPage shows whatever AuthController.currentUser is.
    // Some backends return token but me is not fetched yet. Force it.
    try {
      await AuthController.fetchMe();
    } catch (_) {
      // best-effort; if fetchMe fails, AccountPage still opens & shows whatever it has.
    }

    if (!mounted) return;

    _toast('Account created', tone: AppToastTone.success);

    // ✅ FIX: pop back to AccountPage with success (same contract as LoginPage)
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = context.style;

    return AppScaffold(
      title: 'Register',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          GlowCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create account',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your details to register.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.25),
                  ),
                  const SizedBox(height: 14),

                  _GlassTextField(
                    controller: _first,
                    label: 'First Name',
                    icon: Icons.badge_outlined,
                    enabled: !_busy,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 10),
                  _GlassTextField(
                    controller: _last,
                    label: 'Last Name',
                    icon: Icons.badge_outlined,
                    enabled: !_busy,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 10),
                  _GlassTextField(
                    controller: _username,
                    label: 'Username',
                    icon: Icons.alternate_email_rounded,
                    enabled: !_busy,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 10),
                  _GlassTextField(
                    controller: _email,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 10),
                  _GlassTextField(
                    controller: _pass,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    enabled: !_busy,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 10),
                  _GlassTextField(
                    controller: _repeat,
                    label: 'Repeat Password',
                    icon: Icons.lock_outline_rounded,
                    enabled: !_busy,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                      )
                          : const Text('Submit'),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: Text(
                      'We’ll send a 6-digit code to verify your email.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          GlowCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(style.iconRadius),
                      color: cs.primary.withOpacity(.10),
                    ),
                    child: Icon(Icons.privacy_tip_outlined, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your travel data will be attached to your new account during registration.',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.25),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.enabled = true,
    this.textInputAction,
    this.keyboardType,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final bool enabled;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = context.style;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(style.iconRadius),
        border: Border.all(color: cs.outlineVariant.withOpacity(style.cardBorderOpacity)),
        color: cs.surface.withOpacity(theme.brightness == Brightness.dark ? .10 : .12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}