import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notifications, used to tell the person a voice-triggered alert has
/// started while the app is not on screen. Nothing is pushed from a server.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// Sets the plugin up and asks for notification permission (first call).
  static Future<void> init() async {
    if (_ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          iOS: DarwinInitializationSettings(),
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = true;
    } catch (_) {
      // No notification support here (tests, unsupported platform).
    }
  }

  static Future<void> show(String title, String body) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: 1,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          // While the app is open the countdown screen itself appears, so no
          // banner on top of it.
          iOS: DarwinNotificationDetails(
            presentBanner: false,
            presentList: false,
            presentSound: false,
          ),
          android: AndroidNotificationDetails(
            'dinig_alerts',
            'Emergency alerts',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    } catch (_) {}
  }
}
