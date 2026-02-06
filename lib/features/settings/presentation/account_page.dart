import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';

import '../../../shared/backend/auth_controller.dart';
import '../../../shared/export/travel_pdf_exporter.dart';
import '../../../shared/export/world_map_image_renderer.dart';
import '../../../shared/i18n/app_strings.dart';
import '../../../shared/map/world_map_models.dart';
import '../../../shared/settings/app_settings.dart';
import '../../../shared/storage/local_store.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, required this.worldMapData});

  final WorldMapData worldMapData;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Uint8List? _profilePic;
  bool _loadingPic = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshProfilePic();
  }

  Future<void> _refreshProfilePic() async {
    final auth = AuthScope.of(context);
    if (!auth.isLoggedIn) {
      if (mounted) setState(() => _profilePic = null);
      return;
    }

    setState(() => _loadingPic = true);
    try {
      final bytes = await auth.downloadProfilePic();
      if (!mounted) return;
      setState(() => _profilePic = bytes);
    } finally {
      if (mounted) setState(() => _loadingPic = false);
    }
  }

  Future<void> _showAvatarViewer() async {
    final auth = AuthScope.of(context);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(S.t(context, 'settings_account')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 72,
                backgroundImage: _profilePic != null ? MemoryImage(_profilePic!) : null,
                child: _profilePic == null ? const Icon(Icons.person, size: 72) : null,
              ),
              const SizedBox(height: 12),
              Text(
                auth.isLoggedIn
                    ? 'You can change or remove your profile picture.'
                    : 'Log in to set a profile picture.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: auth.isLoggedIn
                  ? () async {
                final picker = ImagePicker();
                final file = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1024,
                  imageQuality: 85,
                );
                if (file == null) return;

                final bytes = await file.readAsBytes();
                await auth.uploadProfilePicBytes(bytes, filename: file.name);

                if (!mounted) return;
                Navigator.of(ctx).pop();
                await _refreshProfilePic();
              }
                  : null,
              child: const Text('Change'),
            ),
            TextButton(
              onPressed: auth.isLoggedIn
                  ? () async {
                await auth.deleteProfilePic();
                if (!mounted) return;
                Navigator.of(ctx).pop();
                setState(() => _profilePic = null);
              }
                  : null,
              child: const Text('Remove'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(S.t(context, 'cancel')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAuthDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const AuthDialog(),
    );

    // result: true = success, false/null = cancel
    if (result == true) {
      await _refreshProfilePic();
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final auth = AuthScope.of(context);
    if (!auth.isLoggedIn) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'Warning: This permanently deletes your account from the server.\n'
              'Your local data will also be cleared after logout.\n\n'
              'Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(S.t(context, 'cancel'))),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await auth.deleteAccount();
      if (!mounted) return;
      setState(() => _profilePic = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _exportTravelPdf(BuildContext context) async {
    // Temporary / MVP flow:
    const appName = 'Been Around';
    const displayName = 'Me';

    try {
      final includeMemos = await _askIncludeMemos(context);
      if (includeMemos == null) return; // user canceled

      final settings = AppSettingsScope.of(context);
      final lightScheme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
      ).colorScheme;

      final borderColor = lightScheme.outlineVariant.withAlpha(180);

      final selectedIds = await LocalStore.loadSelectedCountries();

      final mapPng = await WorldMapImageRenderer.renderPng(
        map: widget.worldMapData,
        selectedIds: selectedIds,
        selectedColor: settings.selectedCountryColor,
        multicolor: settings.selectedCountryColorMode ==
            SelectedCountryColorMode.multicolor,
        palette: AppSettingsController.countryColorPalette,
        borderColor: borderColor,
        pixelSize: const Size(2400, 1200),
      );

      final pdfBytes = await TravelPdfExporter.buildPdf(
        map: widget.worldMapData,
        appName: appName,
        displayName: displayName,
        // Change this if your logo asset is different:
        logoAssetPath: TravelPdfExporter.defaultLogoAssetPath,
        worldMapPngBytes: mapPng,
        includeMemos: includeMemos,
      );

      final now = DateTime.now();
      final y = now.year.toString().padLeft(4, '0');
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'TravelData_$y-$m-$d.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${S.t(context, 'export_failed')} $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final me = auth.user;

    final displayName = me?.displayName ?? 'Guest';
    final username = me != null ? '@${me.username}' : '@guest';

    return Scaffold(
      appBar: AppBar(title: Text(S.t(context, 'settings_account'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const SizedBox(height: 8),

          // =========================
          // ✅ Profile header section
          // =========================
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _loadingPic ? null : _showAvatarViewer,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundImage: _profilePic != null ? MemoryImage(_profilePic!) : null,
                    child: _profilePic == null ? const Icon(Icons.person, size: 40) : null,
                  ),
                  if (_loadingPic)
                    const SizedBox(
                      width: 92,
                      height: 92,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              displayName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              username,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 24),

          // Existing PDF export
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text(S.t(context, 'export_travel_data')),
            subtitle: Text(S.t(context, 'export_travel_data_sub')),
            onTap: () => _exportTravelPdf(context),
          ),

          const Divider(height: 24),

          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                if (!auth.isLoggedIn)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: auth.isBusy ? null : _showAuthDialog,
                      icon: const Icon(Icons.login),
                      label: const Text('Log in'),
                    ),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: auth.isBusy
                          ? null
                          : () async {
                        await auth.logout();
                        if (!mounted) return;
                        setState(() => _profilePic = null);
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Log out'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: auth.isBusy ? null : _confirmDeleteAccount,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete account'),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<bool?> _askIncludeMemos(BuildContext context) async {
    bool includeMemos = true;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text(S.t(context, 'export_options')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(S.t(context, 'export_option_msg')),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: includeMemos,
                    onChanged: (v) => setState(() {
                      includeMemos = v ?? true;
                    }),
                    title: Text(S.t(context, 'include_notes')),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: Text(S.t(context, 'cancel')),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(includeMemos),
                  child: Text(S.t(context, 'export')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  bool isRegister = false;
  bool busy = false;

  // Register fields
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();

  // Shared
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = AuthScope.of(context);

    final username = usernameCtrl.text.trim();
    final password = passwordCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill username & password')),
      );
      return;
    }

    if (isRegister) {
      final first = firstNameCtrl.text.trim();
      final last = lastNameCtrl.text.trim();
      if (first.isEmpty || last.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill first & last name')),
        );
        return;
      }
    }

    setState(() => busy = true);

    try {
      FocusScope.of(context).unfocus();

      if (isRegister) {
        final migrate = await LocalStore.hasGuestData();
        await auth.register(
          firstName: firstNameCtrl.text.trim(),
          lastName: lastNameCtrl.text.trim(),
          username: username,
          password: password,
          migrateGuestData: migrate,
        );
      } else {
        await auth.login(username: username, password: password);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true); // success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${isRegister ? 'Register' : 'Login'} failed: $e')),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isRegister ? 'Register' : 'Log in'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode toggle
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Log in')),
                      ButtonSegment(value: true, label: Text('Register')),
                    ],
                    selected: {isRegister},
                    onSelectionChanged: busy
                        ? null
                        : (s) => setState(() => isRegister = s.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (isRegister) ...[
              TextField(
                controller: firstNameCtrl,
                decoration: const InputDecoration(labelText: 'First name'),
                textInputAction: TextInputAction.next,
              ),
              TextField(
                controller: lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Last name'),
                textInputAction: TextInputAction.next,
              ),
            ],

            TextField(
              controller: usernameCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: passwordCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onSubmitted: (_) => busy ? null : _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: busy ? null : _submit,
          child: busy
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(isRegister ? 'Register' : 'Log in'),
        ),
      ],
    );
  }
}

