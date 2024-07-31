import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:voluntariado_app/app.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:voluntariado_app/screens/chat_list_screen.dart';
import 'constants.dart';
import 'firebase_options.dart';
import 'service/activity_service.dart';
import 'service/badge_service.dart';
import 'service/firestore_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Gemini.init(apiKey: gemini);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    if (notification != null && android != null) {
      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (context) => const ChatListScreen(),
      ));

    }
  });

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(
    MultiProvider(
      providers: [
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        Provider<ActivityService>(
          create: (_) => ActivityService(),
        ),
        Provider<BadgeService>(
          create: (_) => BadgeService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
