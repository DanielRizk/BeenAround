import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/i18n/app_strings.dart';
import '../../../shared/ui_kit/app_cards.dart';
import '../../../shared/ui_kit/app_scaffold.dart';
import '../../../shared/ui_kit/app_style.dart';

class CountryCitiesPage extends StatelessWidget {
  final String iso2;
  final String countryName;

  final Set<String> visitedCountryIds;
  final List<String> visitedCities;
  final List<String> allCities;

  const CountryCitiesPage({
    super.key,
    required this.iso2,
    required this.countryName,
    required this.visitedCountryIds,
    required this.visitedCities,
    required this.allCities,
  });

  @override
  Widget build(BuildContext context) {
    final visitedSet = visitedCities.map((e) => e.trim()).toSet();
    final allSorted = [...allCities]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final visitedCount = visitedSet.length;
    final totalCount = allCities.length;

    final isVisitedCountry = visitedCountryIds.contains(iso2);

    String flagEmojiFromIso2(String iso2) {
      final s = iso2.toUpperCase();
      if (s.length != 2) return '🏳️';
      final a = s.codeUnitAt(0);
      final b = s.codeUnitAt(1);
      if (a < 65 || a > 90 || b < 65 || b > 90) return '🏳️';
      return String.fromCharCode(0x1F1E6 + (a - 65)) + String.fromCharCode(0x1F1E6 + (b - 65));
    }

    return AppScaffold(
      title: countryName,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Country header gauge
          GlowCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _PremiumGauge(visited: visitedCount, total: totalCount, size: 92),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(flagEmojiFromIso2(iso2), style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Text(
                                  countryName,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${S.t(context, "cities")} $visitedCount/$totalCount',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          isVisitedCountry ? S.t(context, "country_visited") : S.t(context, "country_not_visited"),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            S.t(context, "cities"),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),

          // Cities list: each card separate, motion interaction, no legacy ListTile
          for (final city in allSorted)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CityCard(
                city: city,
                visited: visitedSet.contains(city.trim()),
              ),
            ),
        ],
      ),
    );
  }
}

class _CityCard extends StatefulWidget {
  final String city;
  final bool visited;

  const _CityCard({
    required this.city,
    required this.visited,
  });

  @override
  State<_CityCard> createState() => _CityCardState();
}

class _CityCardState extends State<_CityCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = context.style;

    final accent = widget.visited ? cs.primary : cs.onSurfaceVariant;

    return Opacity(
      opacity: widget.visited ? 1.0 : 0.50,
      child: GlowCard(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: () {}, // keep non-interactive for now; preserves “row feel” without navigation changes
          child: AnimatedScale(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            scale: _down ? style.pressScale : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              color: _down ? accent.withOpacity(.06) : Colors.transparent,
              child: Row(
                children: [
                  Icon(
                    widget.visited ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.city,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
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

class _PremiumGauge extends StatelessWidget {
  final int visited;
  final int total;
  final double size;

  const _PremiumGauge({
    required this.visited,
    required this.total,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final t = total <= 0 ? 0.0 : (visited / total).clamp(0.0, 1.0);
    final pct = (t * 100).round();

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _PremiumGaugePainter(
              t: t,
              primary: cs.primary,
              secondary: cs.secondary,
              track: cs.outlineVariant.withOpacity(theme.brightness == Brightness.dark ? .35 : .28),
              glow: cs.primary.withOpacity(theme.brightness == Brightness.dark ? .20 : .12),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$pct%',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.3,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '$visited/$total',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumGaugePainter extends CustomPainter {
  _PremiumGaugePainter({
    required this.t,
    required this.primary,
    required this.secondary,
    required this.track,
    required this.glow,
  });

  final double t;
  final Color primary;
  final Color secondary;
  final Color track;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);

    final radius = s * 0.38;
    final stroke = s * 0.10;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const start = -math.pi / 2;
    const sweepMax = math.pi * 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = track;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke * 1.25
      ..color = glow
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 0.9);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + sweepMax,
        colors: [primary, secondary, primary],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);

    canvas.drawArc(rect, start, sweepMax, false, trackPaint);

    if (t > 0) {
      final sweep = (sweepMax * t).clamp(0.0, sweepMax);
      canvas.drawArc(rect, start, sweep, false, glowPaint);
      canvas.drawArc(rect, start, sweep, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PremiumGaugePainter old) {
    return old.t != t || old.primary != primary || old.secondary != secondary || old.track != track || old.glow != glow;
  }
}