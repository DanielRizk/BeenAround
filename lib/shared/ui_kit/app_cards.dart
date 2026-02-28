import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_style.dart';

enum CardTone { normal, danger }
enum TileTone { normal, danger }

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.tone = CardTone.normal,
  });

  final String title;
  final Widget child;
  final CardTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final titleColor = tone == CardTone.danger ? cs.error : cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: titleColor, letterSpacing: .2),
          ),
        ),
        GlowCard(tone: tone, child: child),
      ],
    );
  }
}

class GlowCard extends StatefulWidget {
  const GlowCard({super.key, required this.child, this.tone = CardTone.normal});

  final Widget child;
  final CardTone tone;

  @override
  State<GlowCard> createState() => _GlowCardState();
}

class _GlowCardState extends State<GlowCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = context.style;

    final glow = widget.tone == CardTone.danger ? cs.error : cs.primary;
    final r = BorderRadius.circular(style.cardRadius);

    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      scale: _pressed ? style.pressScale : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: [
            BoxShadow(
              blurRadius: _pressed ? 16 : 26,
              offset: const Offset(0, 14),
              color: glow.withOpacity(theme.brightness == Brightness.dark ? .18 : .10),
            ),
          ],
        ),
        child: Listener(
          onPointerDown: (_) => setState(() => _pressed = true),
          onPointerUp: (_) => setState(() => _pressed = false),
          onPointerCancel: (_) => setState(() => _pressed = false),
          child: DecoratedBox(
            // border OUTSIDE clip (no “missing corners”)
            decoration: BoxDecoration(
              borderRadius: r,
              border: Border.all(color: cs.outlineVariant.withOpacity(style.cardBorderOpacity)),
            ),
            child: ClipRRect(
              borderRadius: r,
              clipBehavior: Clip.antiAlias,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: style.cardBlurSigma, sigmaY: style.cardBlurSigma),
                child: Container(
                  color: cs.surface.withOpacity(style.cardSurfaceOpacity),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MotionTile extends StatefulWidget {
  const MotionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.tone = TileTone.normal,
    this.showChevron = true, // ✅ NEW
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final TileTone tone;
  final bool showChevron; // ✅ NEW

  @override
  State<MotionTile> createState() => _MotionTileState();
}

class _MotionTileState extends State<MotionTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = context.style;

    final isDanger = widget.tone == TileTone.danger;
    final accent = isDanger ? cs.error : cs.primary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                color: accent.withOpacity(_down ? .16 : .10),
              ),
              child: Icon(widget.icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDanger ? cs.error : cs.onSurface,
                    ),
                  ),
                  if (widget.subtitle != null &&
                      widget.subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.showChevron) ...[
              const SizedBox(width: 10),
              AnimatedSlide(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                offset: _down ? const Offset(.10, 0) : Offset.zero,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SoftDivider extends StatelessWidget {
  const SoftDivider({super.key});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Divider(height: 1, thickness: 1, color: cs.outlineVariant.withOpacity(.35));
  }
}