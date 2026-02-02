import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<Map<String, dynamic>?> init({
    required void Function(Map<String, dynamic> payload) onTap,
  }) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final raw = resp.payload;
        if (raw == null || raw.isEmpty) return;
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          onTap(decoded);
        }
      },
    );

    // Android 13+ permission
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // If app launched by tapping a notification:
    final details = await _plugin.getNotificationAppLaunchDetails();
    final raw = details?.notificationResponse?.payload;
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  static Future<void> showEnteredCountry({
    required String iso2,
    required String countryName,
  }) async {
    const android = AndroidNotificationDetails(
      'been_around_country_enter',
      'Country detection',
      channelDescription: 'Notify when entering a new country',
      importance: Importance.high,
      priority: Priority.high,
    );

    const ios = DarwinNotificationDetails();

    final payload = jsonEncode({
      'type': 'enter_country',
      'iso2': iso2,
    });

    await _plugin.show(
      iso2.hashCode & 0x7fffffff,
      'New Country, Yaaay!!!',
      'You made it to $countryName. Tap to add it.',
      const NotificationDetails(android: android, iOS: ios),
      payload: payload,
    );
  }
}
