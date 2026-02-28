import 'package:flutter/material.dart';
import '../../../shared/i18n/app_strings.dart';
import '../../../shared/settings/app_settings.dart';
import '../../../shared/ui_kit/app_cards.dart';
import '../../../shared/ui_kit/app_scaffold.dart';
import '../../../shared/ui_kit/app_style.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return AppScaffold(
      title: S.t(context, 'settings_language'),
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          final code = settings.locale.languageCode;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              SectionCard(
                title: S.t(context, 'settings_language'),
                child: Column(
                  children: [
                    _LanguageTile(
                      title: S.t(context, 'lang_en'),
                      value: 'en',
                      selected: code == 'en',
                      onTap: () => settings.setLocale(const Locale('en')),
                    ),
                    const SoftDivider(),
                    _LanguageTile(
                      title: S.t(context, 'lang_de'),
                      value: 'de',
                      selected: code == 'de',
                      onTap: () => settings.setLocale(const Locale('de')),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguageTile extends StatefulWidget {
  const _LanguageTile({
    required this.title,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_LanguageTile> createState() => _LanguageTileState();
}

class _LanguageTileState extends State<_LanguageTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = context.style;

    final accent = cs.primary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        color: _down ? accent.withOpacity(.06) : Colors.transparent,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(style.iconRadius),
                color: accent.withOpacity(widget.selected ? .16 : .10),
              ),
              child: Icon(
                Icons.language_rounded,
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: widget.selected
                  ? Icon(
                Icons.check_circle_rounded,
                key: const ValueKey(true),
                color: accent,
              )
                  : Icon(
                Icons.radio_button_unchecked_rounded,
                key: const ValueKey(false),
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}