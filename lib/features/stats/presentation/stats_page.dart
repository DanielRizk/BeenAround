import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../shared/i18n/app_strings.dart';
import '../../../shared/ui_kit/app_cards.dart';
import '../../../shared/ui_kit/app_scaffold.dart';
import '../../../shared/ui_kit/app_style.dart';
import 'continent_countries_page.dart';

class StatsPage extends StatelessWidget {
  final ValueListenable<Set<String>> selectedCountryIds;
  final ValueListenable<Map<String, List<String>>> citiesByCountry;

  final Map<String, String> countryNameById; // iso2 -> name (if available)
  final Map<String, List<String>> iso2ToCities; // iso2 -> all cities
  final Map<String, String> iso2ToContinent; // iso2 -> continent

  const StatsPage({
    super.key,
    required this.selectedCountryIds,
    required this.citiesByCountry,
    required this.countryNameById,
    required this.iso2ToCities,
    required this.iso2ToContinent,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: selectedCountryIds,
      builder: (context, visitedCountriesSet, _) {
        return ValueListenableBuilder<Map<String, List<String>>>(
          valueListenable: citiesByCountry,
          builder: (context, visitedCitiesMap, __) {
            final totalCountries = iso2ToCities.keys.length; // ISO2 universe
            final visitedCountries = visitedCountriesSet.length;

            final totalCities = iso2ToCities.values.fold<int>(0, (a, b) => a + b.length);
            final visitedCities = visitedCitiesMap.values.fold<int>(0, (a, b) => a + b.length);

            final continents = _buildContinentsIndex();

            return AppScaffold(
              title: S.t(context, 'tab_stats'),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _SectionHeader(title: S.t(context, 'worldwide')),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: GlowCard(
                          child: _GaugeCardContent(
                            title: S.t(context, 'tab_countries'),
                            visited: visitedCountries,
                            total: totalCountries,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlowCard(
                          child: _GaugeCardContent(
                            title: S.t(context, 'cities'),
                            visited: visitedCities,
                            total: totalCities,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),
                  _SectionHeader(title: S.t(context, 'continents')),
                  const SizedBox(height: 10),

                  for (final entry in continents)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ContinentCard(
                        continent: entry.continent,
                        iso2s: entry.iso2s,
                        visitedCountryIds: visitedCountriesSet,
                        citiesByCountry: visitedCitiesMap,
                        iso2ToCities: iso2ToCities,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ContinentCountriesPage(
                                continent: entry.continent,
                                iso2s: entry.iso2s,
                                visitedCountryIds: visitedCountriesSet,
                                citiesByCountry: visitedCitiesMap,
                                countryNameById: countryNameById,
                                iso2ToCities: iso2ToCities,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<_ContinentBucket> _buildContinentsIndex() {
    final buckets = <String, List<String>>{};

    for (final rawIso2 in iso2ToCities.keys) {
      final iso2 = rawIso2.trim().toUpperCase();
      final continent = iso2ToContinent[iso2] ?? 'Other';
      buckets.putIfAbsent(continent, () => <String>[]).add(iso2);
    }

    final out = buckets.entries.map((e) => _ContinentBucket(e.key, (e.value..sort()))).toList();

    out.sort((a, b) {
      if (a.continent == 'Other') return 1;
      if (b.continent == 'Other') return -1;
      return a.continent.compareTo(b.continent);
    });

    return out;
  }
}

class _ContinentBucket {
  final String continent;
  final List<String> iso2s;
  _ContinentBucket(this.continent, this.iso2s);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _GaugeCardContent extends StatelessWidget {
  final String title;
  final int visited;
  final int total;

  const _GaugeCardContent({
    required this.title,
    required this.visited,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Column(
        children: [
          _PremiumGauge(visited: visited, total: total, size: 96),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ContinentCard extends StatefulWidget {
  final String continent;
  final List<String> iso2s;
  final Set<String> visitedCountryIds;
  final Map<String, List<String>> citiesByCountry;
  final Map<String, List<String>> iso2ToCities;
  final VoidCallback onTap;

  const _ContinentCard({
    required this.continent,
    required this.iso2s,
    required this.visitedCountryIds,
    required this.citiesByCountry,
    required this.iso2ToCities,
    required this.onTap,
  });

  @override
  State<_ContinentCard> createState() => _ContinentCardState();
}

class _ContinentCardState extends State<_ContinentCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = context.style;

    final visitedCountries = widget.iso2s.where(widget.visitedCountryIds.contains).length;
    final totalCountries = widget.iso2s.length;

    final totalCities = widget.iso2s.fold<int>(0, (a, iso) => a + (widget.iso2ToCities[iso]?.length ?? 0));
    final visitedCities = widget.iso2s.fold<int>(0, (a, iso) => a + (widget.citiesByCountry[iso]?.length ?? 0));

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
            padding: const EdgeInsets.all(14),
            color: _down ? cs.primary.withOpacity(.05) : Colors.transparent,
            child: Row(
              children: [
                _PremiumGauge(visited: visitedCountries, total: totalCountries, size: 76),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.continent,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${S.t(context, 'tab_countries')} $visitedCountries/$totalCountries',
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${S.t(context, 'cities')} $visitedCities/$totalCities',
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
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

    // No box. No border. Just ring + clean type, centered.
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

    // Breathing room so nothing clips/overflows.
    final radius = s * 0.38;
    final stroke = s * 0.10; // premium thickness, not chunky
    final rect = Rect.fromCircle(center: center, radius: radius);

    const start = -math.pi / 2;
    const sweepMax = math.pi * 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = track;

    // Soft glow under the progress (subtle, premium)
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke * 1.25
      ..color = glow
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 0.9);

    // Progress paint with sweep gradient
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

    // Track
    canvas.drawArc(rect, start, sweepMax, false, trackPaint);

    // Progress (only if > 0)
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