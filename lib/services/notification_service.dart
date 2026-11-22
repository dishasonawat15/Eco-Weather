import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(settings: settings);

    // 🌟 NEW: Ask Android 13+ for permission to show alerts!
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future showPollutionAlert(int aqi) async {
    if (aqi >= 3) { 
      const androidDetails = AndroidNotificationDetails(
        'eco_weather_alerts',
        'Pollution Alerts',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      const platformDetails = NotificationDetails(android: androidDetails);
      
      await _notifications.show(
        id: 0,
        title: '⚠️ High Pollution Alert!',
        body: 'The Air Quality Index is $aqi. Consider wearing a mask outside.',
        notificationDetails: platformDetails,
      );
    }
  }
}