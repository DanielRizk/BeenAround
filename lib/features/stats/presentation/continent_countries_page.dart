import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/i18n/app_strings.dart';
import '../../../shared/ui_kit/app_cards.dart';
import '../../../shared/ui_kit/app_scaffold.dart';
import '../../../shared/ui_kit/app_style.dart';
import 'country_cities_page.dart';

class ContinentCountriesPage extends StatelessWidget {
  final String continent;
  final List<String> iso2s;

  final Set<String> visitedCountryIds;
  final Map<String, List<String>> citiesByCountry; // visited cities
  final Map<String, String> countryNameById; // iso2 -> name (if available)
  final Map<String, List<String>> iso2ToCities; // all cities

  const ContinentCountriesPage({
    super.key,
    required this.continent,
    required this.iso2s,
    required this.visitedCountryIds,
    required this.citiesByCountry,
    required this.countryNameById,
    required this.iso2ToCities,
  });

  @override
  Widget build(BuildContext context) {
    final visitedCountries = iso2s.where(visitedCountryIds.contains).length;

    // Cities totals for this continent
    final totalCities = iso2s.fold<int>(0, (a, iso) => a + (iso2ToCities[iso]?.length ?? 0));
    final visitedCities = iso2s.fold<int>(0, (a, iso) => a + (citiesByCountry[iso]?.length ?? 0));

    return AppScaffold(
      title: continent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Header (continent totals)
          GlowCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _PremiumGauge(visited: visitedCountries, total: iso2s.length, size: 92),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          continent,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.2),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${S.t(context, 'tab_countries')} $visitedCountries/${iso2s.length}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${S.t(context, 'cities')} $visitedCities/$totalCities',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Countries (each card separate)
          for (final iso in iso2s)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CountryCard(
                iso2: iso,
                name: countryNameById[iso] ?? iso,
                isVisited: visitedCountryIds.contains(iso),
                visitedCities: citiesByCountry[iso]?.length ?? 0,
                totalCities: iso2ToCities[iso]?.length ?? 0,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CountryCitiesPage(
                        iso2: iso,
                        countryName: countryNameById[iso] ?? iso,
                        visitedCountryIds: visitedCountryIds,
                        visitedCities: citiesByCountry[iso] ?? const <String>[],
                        allCities: iso2ToCities[iso] ?? const <String>[],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CountryCard extends StatefulWidget {
  final String iso2;
  final String name;
  final bool isVisited;
  final int visitedCities;
  final int totalCities;
  final VoidCallback onTap;

  const _CountryCard({
    required this.iso2,
    required this.name,
    required this.isVisited,
    required this.visitedCities,
    required this.totalCities,
    required this.onTap,
  });

  @override
  State<_CountryCard> createState() => _CountryCardState();
}

class _CountryCardState extends State<_CountryCard> {
  bool _down = false;

  String _flagEmojiFromIso2(String iso2) {
    final s = iso2.toUpperCase();
    if (s.length != 2) return '🏳️';
    final a = s.codeUnitAt(0);
    final b = s.codeUnitAt(1);
    if (a < 65 || a > 90 || b < 65 || b > 90) return '🏳️';
    return String.fromCharCode(0x1F1E6 + (a - 65)) + String.fromCharCode(0x1F1E6 + (b - 65));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = context.style;

    return GlowCard(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          scale: _down ? style.pressScale : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: _down ? cs.primary.withOpacity(.05) : Colors.transparent,
            child: Row(
              children: [
                _PremiumGauge(visited: widget.visitedCities, total: widget.totalCities, size: 64),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(_flagEmojiFromIso2(widget.iso2), style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Text(
                                widget.name,
                                maxLines: 1,
                                softWrap: false,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${S.t(context, 'cities')} ${widget.visitedCities}/${widget.totalCities}',
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),
                Icon(
                  widget.isVisited ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: widget.isVisited ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  offset: _down ? const Offset(.10, 0) : Offset.zero,
                  child: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                ),
              ],
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

    // breathing room so nothing clips
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
    return old.t != t ||
        old.primary != primary ||
        old.secondary != secondary ||
        old.track != track ||
        old.glow != glow;
  }
}