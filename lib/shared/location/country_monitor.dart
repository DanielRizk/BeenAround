import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../notifications/local_notification_service.dart';
import '../storage/local_store.dart';

class CountryMonitor {
  CountryMonitor({
    this.cooldown = const Duration(hours: 12),

    /// Only used as a fallback when stream is silent.
    this.staleAfter = const Duration(minutes: 20),

    /// How often we check for a stale stream and run a fallback poll.
    this.staleCheckInterval = const Duration(minutes: 10),

    /// Debounce / jitter protection for country changes.
    this.minSecondsBetweenGeocodes = 60,

    /// Require the same ISO2 N times before notifying (border jitter protection).
    this.requiredStableReads = 2,
  });

  /// Minimum time between notifications (global).
  /// (You already store last notified ISO2 + ts in LocalStore.)
  final Duration cooldown;

  /// If we don't receive a stream update for this long, do a poll fallback.
  final Duration staleAfter;

  /// How often to evaluate "is stream stale?"
  final Duration staleCheckInterval;

  /// Prevent reverse-geocoding on every location tick.
  final int minSecondsBetweenGeocodes;

  /// Require iso2 to be detected consistently before notifying.
  final int requiredStableReads;

  StreamSubscription<Position>? _sub;
  Timer? _staleTimer;

  int _lastStreamMs = 0;
  int _lastGeocodeMs = 0;

  // stability buffer
  String? _lastDetectedIso2;
  int _sameIso2Count = 0;

  void _log(String msg) {
    if (kDebugMode) debugPrint('[CountryMonitor] $msg');
  }

  Future<void> start() async {
    _log('start()');

    if (!await Geolocator.isLocationServiceEnabled()) {
      _log('Location services OFF');
      return;
    }

    var perm = await Geolocator.checkPermission();
    _log('permission=$perm');
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      _log('permission after request=$perm');
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _log('permission denied -> stop');
      return;
    }

    // Primary: stream updates (battery-friendly)
    // For country-level detection, low/medium accuracy + larger distanceFilter is enough.
    const settings = LocationSettings(
      accuracy: LocationAccuracy.low,
      distanceFilter: 1000, // 1km — good for country detection
    );

    await _sub?.cancel();
    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
          (pos) async {
        _lastStreamMs = DateTime.now().millisecondsSinceEpoch;
        await _handlePosition(pos, source: 'stream');
      },
      onError: (e) => _log('stream error: $e'),
    );

    // Fallback: check if stream is stale, then poll once
    _staleTimer?.cancel();
    _staleTimer = Timer.periodic(staleCheckInterval, (_) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final ageMs = now - _lastStreamMs;

      if (_lastStreamMs == 0) {
        // stream hasn't emitted yet, try one poll
        _log('stream has not emitted yet -> poll fallback');
        await checkNow();
        return;
      }

      if (ageMs > staleAfter.inMilliseconds) {
        _log('stream stale (${(ageMs / 1000).round()}s) -> poll fallback');
        await checkNow();
      }
    });

    // Immediate: one check at startup so it works even while stationary
    await checkNow();
  }

  Future<void> stop() async {
    _log('stop()');
    await _sub?.cancel();
    _sub = null;
    _staleTimer?.cancel();
    _staleTimer = null;
  }

  /// One-shot location check. Uses current position with timeout,
  /// then falls back to last known position.
  Future<void> checkNow() async {
    _log('checkNow()');

    Position? pos;

    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 20),
      );
      _log('got current position');
    } on TimeoutException {
      _log('getCurrentPosition TIMEOUT');
    } catch (e) {
      _log('getCurrentPosition failed: $e');
    }

    pos ??= await Geolocator.getLastKnownPosition();

    if (pos == null) {
      _log('no lastKnownPosition yet');
      return;
    }

    await _handlePosition(pos, source: 'poll');
  }

  Future<void> _handlePosition(Position pos, {required String source}) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Rate limit reverse-geocoding (expensive)
    final sinceGeocode = nowMs - _lastGeocodeMs;
    if (_lastGeocodeMs != 0 &&
        sinceGeocode < minSecondsBetweenGeocodes * 1000) {
      _log('$source skip geocode (rate limit)');
      return;
    }
    _lastGeocodeMs = nowMs;

    _log('$source pos=${pos.latitude},${pos.longitude}');

    // Cooldown / anti-spam
    final lastNotify = await LocalStore.loadLastCountryNotify();
    if (lastNotify != null) {
      final ageMs = nowMs - lastNotify.timestampMs;
      if (ageMs < cooldown.inMilliseconds) {
        _log('cooldown active -> skip (${(ageMs / 60000).round()} min old)');
        return;
      }
    }

    // Reverse geocode -> iso2
    List<Placemark> placemarks;
    try {
      placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
    } catch (e) {
      _log('reverse geocode failed: $e');
      return;
    }

    if (placemarks.isEmpty) {
      _log('no placemarks -> skip');
      return;
    }

    final pm = placemarks.first;
    final iso2 = (pm.isoCountryCode ?? '').trim().toUpperCase();
    final countryName = (pm.country ?? iso2).trim();

    if (iso2.isEmpty) {
      _log('iso2 empty -> skip');
      return;
    }

    _log('detected iso2=$iso2 country=$countryName');

    // Border jitter protection: require stable reads
    if (_lastDetectedIso2 == iso2) {
      _sameIso2Count++;
    } else {
      _lastDetectedIso2 = iso2;
      _sameIso2Count = 1;
    }

    if (_sameIso2Count < requiredStableReads) {
      _log('iso2 not stable yet ($_sameIso2Count/$requiredStableReads) -> skip');
      return;
    }

    // If already visited => do nothing
    final visited = await LocalStore.loadSelectedCountries();
    if (visited.contains(iso2)) {
      _log('$iso2 already visited -> skip');
      return;
    }

    // If we already notified same country last time => skip
    if (lastNotify != null && lastNotify.iso2 == iso2) {
      _log('already notified for $iso2 -> skip');
      return;
    }

    _log('SHOW notification for $iso2');
    await LocalNotificationService.showEnteredCountry(
      iso2: iso2,
      countryName: countryName,
    );

    await LocalStore.saveLastCountryNotify(
      iso2: iso2,
      timestampMs: nowMs,
    );
  }
}
