import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notify_inapp/notify_inapp.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class NotificationService {
  Future<void> setFCMToken(String token) async {
    // Здесь вы можете отправить токен на ваш сервер или использовать его по вашему усмотрению.
    print("FCM Token set: $token");
    // Пример: await ApiService.sendTokenToServer(token);
  }
}

class _MyHomePageState extends State<MyHomePage> {
  late FirebaseMessaging messaging;
  String? _token;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  Notify notify = Notify();

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _createNotificationChannel();
    initFirebase();
  }

  initFirebase() async {
    final notificationSettings =
        await FirebaseMessaging.instance.requestPermission(
      provisional: false,
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      sound: true,
    );

    if (notificationSettings.authorizationStatus ==
        AuthorizationStatus.authorized) {
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        await NotificationService().setFCMToken(fcmToken);
        setState(() {
          _token = fcmToken; // Сохраняем токен в переменной и обновляем интерфейс
        });
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleMessage(message);
      });
    }
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    // foreground notification
    if (message.notification != null) {
      notify.show(
        context,
        view(message.notification?.title ?? '-', message.notification?.body ?? '-'),
      );
    }
  }

  Widget view(String title, String text) {
    return GestureDetector(
      onTap: () {
        if (notify.isShown()) {
          notify.dismiss(false);
        }
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Container(
          padding: const EdgeInsets.only(
            left: 25,
            right: 25,
            top: 15,
            bottom: 15,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                spreadRadius: 0,
                color: Color(0x4d000000),
                blurRadius: 15,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff333333),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Color(0xff333333),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'default_channel_id',
        'Default notifications',
        description: 'Channel for default notifications',
        importance: Importance.max,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      print('Notification channel created');
    }
  }

  Future<void> _showNotification(RemoteNotification notification) async {
    print('Notification Title: ${notification.title}');
    print('Notification Body: ${notification.body}');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'default_channel_id',
      'Default notifications',
      channelDescription: 'Channel for default notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text("FCM Token:"),
            _token != null
                ? SelectableText(
                    _token ?? "Получение токена...",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  )
                : const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}