import 'package:aerosense_ph/features/app/loading_screen/loading_screen.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/home_page.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/login.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/monitorpage.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/sensor_location_selection.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/signup_page.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/data_timer_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/aqa_provider.dart'; // Consider renaming for clarity
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Your existing notification setup
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAHXv3UO-hpkfdRe_StKD9vSNM8-gi5-bk",
          appId: "1:155615617283:web:90da026bc9166c09ab0936",
          messagingSenderId: "155615617283",
          projectId: "aerosense-c0bb4",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }

    FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: true);

    await initializeNotifications();

    const String blynkAuthToken = 'Cc4I-8AMONW2CZwWkd-bZEz10otAcMOw';

    runApp(const MyApp(blynkAuthToken: blynkAuthToken));

    // Start HazardousEventMonitor after the app is initialized
    final monitor = HazardousEventMonitor();
    monitor.startMonitoring(); // Start monitoring hazardous events
  } catch (e) {
    print("Error initializing Firebase or Notifications: $e");
  }
}

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'aerosense_alerts',
    'Aerosense Alerts',
    description: 'Notifications for air quality alerts',
    importance: Importance.high,
    playSound: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

class MyApp extends StatelessWidget {
  final String blynkAuthToken;

  const MyApp({super.key, required this.blynkAuthToken});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AQAProvider(blynkAuthToken)),
        ChangeNotifierProvider(create: (_) => Temperature(blynkAuthToken)),
        ChangeNotifierProvider(create: (_) => Humidity(blynkAuthToken)),
        ChangeNotifierProvider(
            create: (_) => NotificationProvider(blynkAuthToken)),
        Provider<DataTimerService>(create: (_) => DataTimerService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const Loading(),
          '/login': (context) => const Login(),
          '/signup': (context) => const SignupPage(),
          '/home': (context) {
            final String selectedLocation =
                ModalRoute.of(context)?.settings.arguments as String? ??
                    'Bedroom';
            return HomePage(selectedLocation: selectedLocation);
          },
          '/sensorlocation': (context) => const SensorSelector(),
        },
      ),
    );
  }
}
