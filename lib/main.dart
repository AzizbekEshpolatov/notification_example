import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class MyFirebaseMessagingService {
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint(
      "📌 BACKGROUND yoki TERMINATE holatida keldi: ${message.notification?.title} - ${message.notification?.body}",
    );
    if (message.notification != null) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'high_importance_channel',
          title: message.notification?.title ?? "New Notification",
          body: message.notification?.body ?? "You have a new message.",
          displayOnBackground: true,
        ),
      );
    }
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseService.initialize();

  FirebaseMessaging.onBackgroundMessage(
    MyFirebaseMessagingService.handleBackgroundMessage,
  );

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      debugPrint("📌 TERMINATE holatida kelgan xabar: ${message.notification?.title} - ${message.notification?.body}");
      MyFirebaseMessagingService.handleBackgroundMessage(message);
    } else {
      debugPrint("❌ TERMINATE holatda hech qanday xabar kelmadi.");
    }
  });

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
            ],
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FirebaseService {
  static Future<void> initialize() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    await _requestPermission();
  }

  static Future<void> _requestPermission() async {
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

  Future<void> initialize() async {
    await _initializeAwesomeNotifications();
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
      displayOnForeground: false,
      displayOnBackground: true,
    ),
  );
}
