import 'dart:math' as math;
import 'package:flutter/widgets.dart';

class LabelAnchorFinder {
  /// Computes an anchor inside the "main blob" (largest connected component)
  /// and as central as possible (max distance to border samples).
  static Offset findMainLandAnchor({
    required Path path,
    required Rect bounds,
    int grid = 40,          // increase -> better, slower
    int borderSamples = 300 // increase -> better, slower
  }) {
    // 1) Sample border points along the path (approx distance-to-edge)
    final border = _sampleBorder(path, borderSamples);
    if (border.isEmpty) return bounds.center;

    // 2) Build a grid over the bounds and mark inside cells
    final w = bounds.width;
    final h = bounds.height;
    if (w <= 0 || h <= 0) return bounds.center;

    final cols = grid;
    final rows = math.max(10, (grid * (h / w)).round()); // keep aspect ratio-ish

    final dx = w / cols;
    final dy = h / rows;

    final inside = List.generate(rows, (_) => List<bool>.filled(cols, false));

    bool anyInside = false;
    for (int r = 0; r < rows; r++) {
      final y = bounds.top + (r + 0.5) * dy;
      for (int c = 0; c < cols; c++) {
        final x = bounds.left + (c + 0.5) * dx;
        final p = Offset(x, y);
        final ok = path.contains(p);
        inside[r][c] = ok;
        anyInside = anyInside || ok;
      }
    }
    if (!anyInside) return bounds.center;

    // 3) Find largest connected component (4-neighborhood)
    final compId = List.generate(rows, (_) => List<int>.filled(cols, -1));
    int nextId = 0;
    int bestId = -1;
    int bestCount = 0;

    final q = <_Cell>[];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (!inside[r][c] || compId[r][c] != -1) continue;

        final id = nextId++;
        int count = 0;

        q.clear();
        q.add(_Cell(r, c));
        compId[r][c] = id;

        while (q.isNotEmpty) {
          final cur = q.removeLast();
          count++;

          final rr = cur.r;
          final cc = cur.c;

          // 4-neighbors
          void tryAdd(int nr, int nc) {
            if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) return;
            if (!inside[nr][nc]) return;
            if (compId[nr][nc] != -1) return;
            compId[nr][nc] = id;
            q.add(_Cell(nr, nc));
          }

          tryAdd(rr - 1, cc);
          tryAdd(rr + 1, cc);
          tryAdd(rr, cc - 1);
          tryAdd(rr, cc + 1);
        }

        if (count > bestCount) {
          bestCount = count;
          bestId = id;
        }
      }
    }

    if (bestId == -1) return bounds.center;

    // 4) Within the largest component, choose the point with max distance to border
    Offset bestPoint = bounds.center;
    double bestD2 = -1;

    for (int r = 0; r < rows; r++) {
      final y = bounds.top + (r + 0.5) * dy;
      for (int c = 0; c < cols; c++) {
        if (compId[r][c] != bestId) continue;
        final x = bounds.left + (c + 0.5) * dx;
        final p = Offset(x, y);
        final d2 = _minDist2ToBorder(p, border);
        if (d2 > bestD2) {
          bestD2 = d2;
          bestPoint = p;
        }
      }
    }

    // 5) Small local refinement around bestPoint (hill-climb)
    bestPoint = _refine(path, border, bestPoint, dx * 0.75, iterations: 6);

    return bestPoint;
  }

  static Offset _refine(Path path, List<Offset> border, Offset start, double step,
      {int iterations = 6}) {
    Offset best = start;
    double bestD2 = _minDist2ToBorder(best, border);

    for (int i = 0; i < iterations; i++) {
      bool improved = false;
      for (final dir in const [
        Offset(1, 0),
        Offset(-1, 0),
        Offset(0, 1),
        Offset(0, -1),
        Offset(1, 1),
        Offset(1, -1),
        Offset(-1, 1),
        Offset(-1, -1),
      ]) {
        final cand = best + dir * step;
        if (!path.contains(cand)) continue;
        final d2 = _minDist2ToBorder(cand, border);
        if (d2 > bestD2) {
          bestD2 = d2;
          best = cand;
          improved = true;
        }
      }
      step *= 0.5;
      if (!improved) continue;
    }
    return best;
  }

  static double _minDist2ToBorder(Offset p, List<Offset> border) {
    double best = double.infinity;
    for (final b in border) {
      final dx = p.dx - b.dx;
      final dy = p.dy - b.dy;
      final d2 = dx * dx + dy * dy;
      if (d2 < best) best = d2;
    }
    return best;
  }

  static List<Offset> _sampleBorder(Path path, int samples) {
    final metrics = path.computeMetrics(forceClosed: false).toList();
    if (metrics.isEmpty) return const [];

    final totalLen = metrics.fold<double>(0.0, (s, m) => s + m.length);
    if (totalLen <= 0) return const [];

    final out = <Offset>[];
    for (final m in metrics) {
      final n = math.max(5, (samples * (m.length / totalLen)).round());
      for (int i = 0; i < n; i++) {
        final t = (i + 0.5) / n;
        final pos = m.getTangentForOffset(m.length * t)?.position;
        if (pos != null) out.add(pos);
      }
    }
    return out;
  }
}

class _Cell {
  final int r;
  final int c;
  const _Cell(this.r, this.c);
}
