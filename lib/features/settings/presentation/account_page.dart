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

import '../../../shared/ui_kit/app_cards.dart';
import '../../../shared/ui_kit/app_scaffold.dart';
import '../../../shared/ui_kit/app_toast.dart';
import '../../../shared/ui_kit/app_style.dart';

import 'login_page.dart';
import 'my_data_page.dart';
import 'register_page.dart';

class AccountPage extends StatefulWidget {
  final Future<void> Function() onResetAll;

  const AccountPage({
    super.key,
    required this.worldMapData,
    required this.onResetAll,
  });

  final WorldMapData worldMapData;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Uint8List? _localProfilePicPreview; // UI-only until backend supports update

  bool _loadingMe = false;
  bool _meLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadMe(silent: true);
  }

  Future<void> _loadMe({bool silent = false}) async {
    if (!silent) setState(() => _loadingMe = true);
    try {
      await AuthController.fetchMe();
      _meLoadFailed = false;
    } catch (_) {
      _meLoadFailed = true; // best-effort: show what we have
    } finally {
      if (mounted) setState(() => _loadingMe = false);
    }
  }

  bool get _isLoggedIn => AuthController.currentUser != null;

  void _toast(String msg, {AppToastTone tone = AppToastTone.normal}) {
    if (!mounted) return;
    AppToast.show(context, message: msg, tone: tone);
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _localProfilePicPreview = bytes);

    _toast(
      'Profile picture updated locally (server upload not implemented yet).',
      tone: AppToastTone.success,
    );
  }

  Future<void> _onAvatarTap() async {
    if (!_isLoggedIn) {
      _toast('Log in to set a profile picture.');
      return;
    }

    final action = await showDialog<_AvatarAction>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AvatarPreviewDialog(
        imageBytes: _localProfilePicPreview, // ✅ REQUIRED
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _AvatarAction.change:
        await _pickAvatar();
        break;
      case _AvatarAction.remove:
        if (_localProfilePicPreview == null) return;
        setState(() => _localProfilePicPreview = null);
        _toast('Profile picture removed locally.', tone: AppToastTone.success);
        break;
    }
  }

  Future<void> _goLogin() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    if (ok == true) await _loadMe();
  }

  Future<void> _goRegister() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
    if (ok == true) await _loadMe();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ConfirmLogoutDialog(
        title: 'Log out?',
        message:
        'The app will reset to default on this device after you log out.\n\nYour data is safe. When you log in again, your data will sync back.',
        cancelLabel: S.t(context, 'cancel'),
        confirmLabel: 'Log out',
      ),
    );

    if (ok != true) return;

    await AuthController.logout();
    if (!mounted) return;

    setState(() {
      _localProfilePicPreview = null;
      _meLoadFailed = false;
    });

    await widget.onResetAll();

    if (!mounted) return;
    _toast('Logged out', tone: AppToastTone.success);
  }

  Future<void> _exportTravelPdf(BuildContext context) async {
    final me = AuthController.currentUser;

    const appName = 'Been Around';
    final displayName = me == null ? 'Guest' : '${me.firstName} ${me.lastName}'.trim();

    try {
      final includeMemos = await _askIncludeMemos(context);
      if (includeMemos == null) return;

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
        multicolor: settings.selectedCountryColorMode == SelectedCountryColorMode.multicolor,
        palette: AppSettingsController.countryColorPalette,
        borderColor: borderColor,
        pixelSize: const Size(2400, 1200),
      );

      final pdfBytes = await TravelPdfExporter.buildPdf(
        map: widget.worldMapData,
        appName: appName,
        displayName: displayName,
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
      if (!mounted) return;
      _toast('${S.t(context, 'export_failed')} $e', tone: AppToastTone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = context.style;

    final me = AuthController.currentUser;

    final displayName = me == null ? 'Guest' : '${me.firstName} ${me.lastName}'.trim();
    final usernameLine = me == null ? '@guest' : '@${me.username}';

    return AppScaffold(
      title: S.t(context, 'settings_account'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          GlowCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _onAvatarTap,
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.outlineVariant.withOpacity(style.cardBorderOpacity),
                          width: 1,
                        ),
                      ),
                      child: ClipOval(
                        child: _localProfilePicPreview != null
                            ? Image.memory(_localProfilePicPreview!, fit: BoxFit.cover)
                            : Center(
                          child: Icon(Icons.person_rounded, size: 42, color: cs.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.2),
                  ),
                  const SizedBox(height: 4),
                  Text(usernameLine, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _meLoadFailed
                        ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off_rounded, size: 16, color: cs.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(
                            'Offline — showing available profile.',
                            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),
                  if (_loadingMe) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          SectionCard(
            title: S.t(context, 'export_travel_data'),
            child: Column(
              children: [
                MotionTile(
                  icon: Icons.picture_as_pdf_outlined,
                  title: S.t(context, 'export_travel_data'),
                  subtitle: S.t(context, 'export_travel_data_sub'),
                  onTap: () => _exportTravelPdf(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SectionCard(
            title: S.t(context, 'settings_account'),
            child: Column(
              children: _isLoggedIn
                  ? [
                MotionTile(
                  icon: Icons.info_outline_rounded,
                  title: 'My data',
                  subtitle: 'Manage your account data',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MyDataPage(onResetAll: widget.onResetAll)),
                    );
                    await _loadMe(silent: true);
                  },
                ),
                const SoftDivider(),
                MotionTile(
                  icon: Icons.logout_rounded,
                  title: 'Log out',
                  subtitle: 'Sign out from this device',
                  tone: TileTone.danger,
                  onTap: _logout,
                ),
              ]
                  : [
                MotionTile(
                  icon: Icons.login_rounded,
                  title: 'Log in',
                  subtitle: null,
                  onTap: _goLogin,
                ),
                const SoftDivider(),
                MotionTile(
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Register',
                  subtitle: null,
                  onTap: _goRegister,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Future<bool?> _askIncludeMemos(BuildContext context) async {
    bool includeMemos = true;

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return _AccountExportOptionsDialog(
          initial: includeMemos,
          onChanged: (v) => includeMemos = v,
        );
      },
    );
  }
}

enum _AvatarAction { change, remove }

class _AvatarPreviewDialog extends StatelessWidget {
  const _AvatarPreviewDialog({
    required this.imageBytes,
  });

  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasPic = imageBytes != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Profile picture',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -.2,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
              ),
              child: ClipOval(
                child: hasPic
                    ? Image.memory(imageBytes!, fit: BoxFit.cover)
                    : Icon(
                  Icons.person_rounded,
                  size: 72,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Change'),
                onPressed: () => Navigator.of(context).pop(_AvatarAction.change),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                ),
                onPressed: hasPic
                    ? () => Navigator.of(context).pop(_AvatarAction.remove)
                    : null,
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(S.t(context, 'cancel')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmLogoutDialog extends StatelessWidget {
  const _ConfirmLogoutDialog({
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: GlowCard(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.2),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.25),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(cancelLabel),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(confirmLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountExportOptionsDialog extends StatefulWidget {
  const _AccountExportOptionsDialog({
    required this.initial,
    required this.onChanged,
  });

  final bool initial;
  final ValueChanged<bool> onChanged;

  @override
  State<_AccountExportOptionsDialog> createState() => _AccountExportOptionsDialogState();
}

class _AccountExportOptionsDialogState extends State<_AccountExportOptionsDialog> {
  late bool _include = widget.initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = context.style;

    return Material(
      type: MaterialType.transparency,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: GlowCard(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.t(context, 'export_options'),
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        S.t(context, 'export_option_msg'),
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.25),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() {
                          _include = !_include;
                          widget.onChanged(_include);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(style.iconRadius),
                            color: cs.primary.withOpacity(.06),
                            border: Border.all(color: cs.outlineVariant.withOpacity(style.cardBorderOpacity)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _include ? Icons.check_circle_rounded : Icons.circle_outlined,
                                color: _include ? cs.primary : cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  S.t(context, 'include_notes'),
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(null),
                            child: Text(S.t(context, 'cancel')),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(_include),
                            child: Text(S.t(context, 'export')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}