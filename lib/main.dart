import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  ); // Background listener
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseService.initialize();
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Text(
            "Notification Example",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final token = await NotificationService().getToken();
                  debugPrint("FCM TOKEN: $token");
                },
                child: Text("Get Token"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await NotificationService().sendTestNotification();
                  await NotificationService().scheduleNotification();
                },
                child: Text("Send Scheduled Notification"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await scheduleNotification(); // 1 daqiqa keyin notification chiqadi
                },
                child: Text("Send Scheduled Notification"),
              ),
            ],
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

Future<void> scheduleNotification() async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      channelKey: 'high_importance_channel',
      title: 'Scheduled Notification',
      body: 'This notification was scheduled to appear after 1 minute.',
    ),
    schedule: NotificationCalendar(
      second: DateTime.now().second, // Joriy soniyani olamiz
      minute: DateTime.now().minute + 1, // 1 daqiqa keyin
      repeats: false, // Bir martalik notification
      preciseAlarm: true, // Android uchun aniq vaqtni ta'minlaydi
    ),
  );
}

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp();
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    await _requestPermission();
  }

  static Future<void> _requestPermission() async {
    /// permission olyabmiz ilovada!
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  StreamSubscription? _messageSubscription;
  StreamSubscription? _openAppSubscription;

  Future<void> initialize() async {
    await _initializeAwesomeNotifications();
    _setupMessageListeners();
  }

  Future<void> _initializeAwesomeNotifications() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'high_importance_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Important notifications',
        defaultColor: Colors.blue,
        importance: NotificationImportance.High,
        defaultPrivacy: NotificationPrivacy.Public,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      ),
    ]);
  }

  void _setupMessageListeners() {
    _messageSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _openAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleAppOpened,
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'high_importance_channel',
        title: notification.title,
        body: notification.body,
        payload: message.data.cast<String, String?>(),
        displayOnForeground: true,
        displayOnBackground: false,
      ),
    );
  }

  void _handleAppOpened(RemoteMessage message) {
    debugPrint('App opened from notification: ${message.data}');
  }

  Future<String> getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    return token ?? "";
  }

  Future<void> sendTestNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'high_importance_channel',
        title: 'Test Notification',
        body: 'This is a test notification triggered manually.',
        displayOnForeground: true,
      ),
    );
  }

  Future<void> scheduleNotification() async {
    await Future.delayed(Duration(minutes: 1));
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'high_importance_channel',
        title: 'Scheduled Notification',
        body: 'This notification was scheduled after 1 minute.',
        displayOnForeground: true,
        displayOnBackground: true,
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!Firebase.apps.isNotEmpty) {
    await Firebase.initializeApp();
  }

  final notification = message.notification;
  if (notification == null) return;

  if (!(await AwesomeNotifications().isNotificationAllowed())) {
    await NotificationService()._initializeAwesomeNotifications();
  }

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      channelKey: 'high_importance_channel',
      title: notification.title,
      body: notification.body,
      payload: message.data.cast<String, String?>(),
      displayOnForeground: false,
      displayOnBackground: true,
    ),
  );
}
