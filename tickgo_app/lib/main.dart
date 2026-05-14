import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; 
import 'firebase_options.dart';

// Đảm bảo bồ import đúng đường dẫn 2 file này nhé
import 'views/auth/login_screen.dart'; 
import 'views/home/home_screen.dart';
import 'views/main_layout.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> setupPushNotifications() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ Khách hàng đã cho phép nhận thông báo!');
    
    await messaging.subscribeToTopic('new_events');
    print('✅ Đã đăng ký hóng tin từ kênh "new_events" thành công!');

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // 👉 CHỖ NÀY ĐÂY: Biến tên là "settings:" nha bồ!!! 
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', 
      'Thông báo Sự kiện mới', 
      description: 'Kênh này dùng để báo sự kiện mới.',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        // Hàm show cũng xài biến có tên
        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    });

  } else {
    print('❌ Khách hàng từ chối nhận thông báo.');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ FIREBASE KẾT NỐI THÀNH CÔNG!");

    await setupPushNotifications();

  } catch (e) {
    print("❌ LỖI KHỞI TẠO FIREBASE: $e");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TickGo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainLayout(), 
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Colors.blue)),
          );
        }
        
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}