import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

class AQAProvider with ChangeNotifier {
  double _needleValue = 0;
  double _lastNeedleValue = 0;
  final String blynkAuthToken;
  Timer? _timer;
  Timer? _checkSensorTimer;
  bool _isPowerOn = false;
  BuildContext? _context;
  DateTime _lastUpdateTime = DateTime.now();
  bool _isDialogShowing = false;

  AQAProvider(this.blynkAuthToken);

  double get needleValue => _needleValue;
  double get lastNeedleValue => _lastNeedleValue;
  bool get isPowerOn => _isPowerOn;

  void setContext(BuildContext context) {
    _context = context;
  }

  void _startPeriodicUpdate() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPowerOn) {
        _fetchGasValue();
      }
    });

    _checkSensorTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _checkSensorStatus();
    });
  }

  Future<void> _checkSensorStatus() async {
    try {
      final response = await http.get(Uri.parse(
          'http://blynk.cloud/external/api/isHardwareConnected?token=$blynkAuthToken'));

      if (response.statusCode == 200 && response.body == 'true') {
        await _fetchGasValue();

        // Remove all dialogs if the sensor is back online
        if (_isDialogShowing && _context != null) {
          Navigator.of(_context!).popUntil((route) => route.isFirst);
          _isDialogShowing = false;
        }
      } else {
        // Show dialog if the sensor is offline
        if (!_isDialogShowing) {
          _showSensorNotOnlineDialog();
        } else {
          _showSensorNotOnlineDialog();
        }
      }
    } catch (e) {
      print('Error checking sensor status: $e');
    }
  }

  Future<void> _fetchGasValue() async {
    try {
      final response = await http.get(Uri.parse(
          'http://blynk.cloud/external/api/get?token=$blynkAuthToken&V0'));
      if (response.statusCode == 200) {
        _needleValue = double.tryParse(response.body) ?? 0;
        notifyListeners();
      } else {
        print('Failed to fetch gas value: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching gas value: $e');
    }
  }

  void _showSensorNotOnlineDialog() {
    if (_context != null) {
      _isDialogShowing = true;

      showDialog(
        context: _context!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Sensor Not Online'),
            content: const Text(
                'The Aerosensor is not responding. Please check the sensor or network connection.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  _isDialogShowing = false;
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void togglePower() {
    _isPowerOn = !_isPowerOn;
    if (_isPowerOn) {
      _startPeriodicUpdate();
    } else {
      // Cancel the timers before setting the needle value to 0
      _timer?.cancel();
      _checkSensorTimer?.cancel();

      // Strictly set needle value to 0 and notify listeners
      _needleValue = 0;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _checkSensorTimer?.cancel();
    super.dispose();
  }
}

// Temperature provider
class Temperature with ChangeNotifier {
  double _temperature = 0;
  final String blynkAuthToken;
  Timer? _timer;
  bool _isPowerOn = false;

  Temperature(this.blynkAuthToken);

  double get temperature => _temperature;
  bool get isPowerOn => _isPowerOn;

  void _startPeriodicUpdate() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPowerOn) {
        _fetchTemperatureValue();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTemperatureValue() async {
    try {
      final response = await http.get(Uri.parse(
          'http://blynk.cloud/external/api/get?token=$blynkAuthToken&V3'));
      if (response.statusCode == 200) {
        _temperature = double.tryParse(response.body) ?? 0;
        notifyListeners();
      } else {
        print('Failed to fetch temperature value: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching temperature value: $e');
    }
  }

  void togglePower() {
    _isPowerOn = !_isPowerOn;
    if (_isPowerOn) {
      _startPeriodicUpdate();
    } else {
      // Cancel the timer before setting the temperature to 0
      _timer?.cancel();

      // Optionally, wait for a short period to ensure all async operations are completed
      Future.delayed(const Duration(milliseconds: 100), () {
        _temperature = 0;
        notifyListeners();
      });
    }
  }
}

// Humidity provider
class Humidity with ChangeNotifier {
  double _humidity = 0;
  final String blynkAuthToken;
  Timer? _timer;
  bool _isPowerOn = false;

  Humidity(this.blynkAuthToken);

  double get humidity => _humidity;
  bool get isPowerOn => _isPowerOn;

  void _startPeriodicUpdate() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPowerOn) {
        _fetchHumidityValue();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchHumidityValue() async {
    try {
      final response = await http.get(Uri.parse(
          'http://blynk.cloud/external/api/get?token=$blynkAuthToken&V4'));
      if (response.statusCode == 200) {
        _humidity = double.tryParse(response.body) ?? 0;
        notifyListeners();
      } else {
        print('Failed to fetch humidity value: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching humidity value: $e');
    }
  }

  void togglePower() {
    _isPowerOn = !_isPowerOn;
    if (_isPowerOn) {
      _startPeriodicUpdate();
    } else {
      // Cancel the timer before setting the humidity to 0
      _timer?.cancel();

      // Optionally, wait for a short period to ensure all async operations are completed
      Future.delayed(const Duration(milliseconds: 100), () {
        _humidity = 0;
        notifyListeners();
      });
    }
  }
}

class NotificationProvider with ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  final String blynkAuthToken;
  Timer? _timer;
  bool _isPowerOn = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationProvider(this.blynkAuthToken)
      : flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isPowerOn => _isPowerOn;

  Future<void> init() async {
    // Request permission before proceeding
    bool permissionGranted = await checkNotificationPermission();
    if (permissionGranted) {
      await initialize();
    } else {
      // Optionally, notify the user that notification permissions are required
      print(
          "Notification permission denied. The app will not show notifications.");
    }
  }

  // Request permission to show notifications
  Future<bool> checkNotificationPermission() async {
    var status =
        await Permission.notification.status; // Check current permission status
    print('Notification permission status: $status'); // Log the status

    if (!status.isGranted) {
      // Request permission if not granted
      PermissionStatus requestStatus = await Permission.notification.request();
      if (requestStatus.isGranted) {
        return true; // Permission granted
      } else {
        return false; // Permission denied
      }
    }
    return true; // Already granted
  }

  Future<void> initialize() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'aerosense_alerts',
        'Aerosense Alerts',
        description: 'Notifications for air quality alerts',
        importance: Importance.high,
        playSound: true,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  void _startPeriodicUpdate() {
    if (_timer == null || !_timer!.isActive) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_isPowerOn) {
          _fetchNotifications();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Show notification locally
  Future<void> _showLocalNotification(String message) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'aerosense_alerts',
      'Aerosense Alerts',
      channelDescription: 'Notifications for air quality alerts',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      showWhen: true,
      autoCancel: true,
      vibrationPattern: Int64List.fromList([0, 500, 1000, 500]),
    );

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    try {
      await flutterLocalNotificationsPlugin.show(
        0,
        'Aerosense Warning!',
        'Air Quality is $message!',
        platformChannelSpecifics,
        payload: 'item x',
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await http.get(Uri.parse(
          'http://blynk.cloud/external/api/get?token=$blynkAuthToken&V2'));
      if (response.statusCode == 200) {
        List<String> fetchedNotifications = response.body.split('\n');

        Set<String> seenMessages = {};

        _notifications = fetchedNotifications.map((notification) {
          String alertMessage = notification.toLowerCase();
          Color notificationColor = _getColorBasedOnAirQuality(alertMessage);
          double fontSize = _getFontSizeBasedOnAirQuality(alertMessage);

          List<String> alertKeywords = [
            "sensitive levels",
            "unhealthy",
            "harmful",
            "hazardous"
          ];

          // Function to check for keywords in the alert message
          bool containsAlertKeywords(String message) {
            for (String keyword in alertKeywords) {
              if (message.toLowerCase().contains(keyword)) {
                return true;
              }
            }
            return false;
          }

          // Check for notifications
          if (containsAlertKeywords(alertMessage) &&
              !seenMessages.contains(notification)) {
            seenMessages.add(notification);
            _showLocalNotification(notification);
          }

          return {
            'message': notification,
            'color': notificationColor,
            'fontSize': fontSize,
          };
        }).toList();
        notifyListeners();
      } else {
        print('Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  Color _getColorBasedOnAirQuality(String alertMessage) {
    if (alertMessage.contains("good")) {
      return Colors.green;
    } else if (alertMessage.contains("moderate")) {
      return Colors.yellow;
    } else if (alertMessage.contains("sensitive levels")) {
      return Colors.orange;
    } else if (alertMessage.contains("unhealthy")) {
      return Colors.red;
    } else if (alertMessage.contains("harmful")) {
      return Colors.purple;
    } else if (alertMessage.contains("hazardous")) {
      return const Color.fromARGB(255, 144, 41, 41);
    } else {
      return Colors.orange; // Default color if not recognized
    }
  }

  double _getFontSizeBasedOnAirQuality(String alertMessage) {
    return 30.0; // Return a fixed font size
  }

  void togglePower() async {
    _isPowerOn = !_isPowerOn;

    if (_isPowerOn) {
      // Check for notification permission when the power is toggled on
      await checkNotificationPermission();

      // If permission is granted, start the periodic updates
      if (await Permission.notification.isGranted) {
        _startPeriodicUpdate();
      } else {
        // Optionally show a message or an alert explaining the importance of granting permission
        print("Notification permission is required to receive alerts.");
      }
    } else {
      // Stop periodic updates if power is toggled off
      _timer?.cancel();
      _notifications = []; // Clears the notifications
      notifyListeners();
    }
  }

  // Optionally handle app lifecycle changes (when app is backgrounded or resumed)
  void onAppLifecycleChange(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (_isPowerOn) {
        _startPeriodicUpdate();
      }
    }
  }
}

// PowerSwitch widget
class PowerSwitch extends StatefulWidget {
  const PowerSwitch({super.key});

  @override
  _PowerSwitchState createState() => _PowerSwitchState();
}

class BellIcon extends StatefulWidget {
  const BellIcon({super.key});

  @override
  _BellIconState createState() => _BellIconState();
}

class _BellIconState extends State<BellIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 10).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticIn,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      // Ensure you have a NotificationProvider
      builder: (context, notificationProvider, child) {
        // Show bell icon only for unhealthy, very unhealthy, and hazardous conditions
        bool showBellIcon =
            notificationProvider.notifications.any((notification) {
          String message = notification['message'].toLowerCase();
          return message.contains("unhealthy") ||
              message.contains("hazardous") ||
              message.contains("sensitive levels") ||
              message.contains("harmful");
        });

        if (!showBellIcon) {
          return const SizedBox
              .shrink(); // Return an empty widget if no bell icon
        }

        // Vibrate the phone when the bell icon is active
        _vibrate();

        return AnimatedBuilder(
          animation: _animation,
          child: IconButton(
            icon: const Icon(Icons.warning_amber,
                color: Color.fromARGB(255, 162, 31, 31)),
            iconSize: 37,
            onPressed: () {
              _showNotificationDialog(
                  context, notificationProvider.notifications);
            },
          ),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_animation.value, 0), // Shake effect
              child: child,
            );
          },
        );
      },
    );
  }

  void _vibrate() async {
    // Trigger a longer vibration effect without dependencies
    for (int i = 0; i < 3; i++) {
      HapticFeedback.vibrate(); // Trigger vibration
      await Future.delayed(
          const Duration(milliseconds: 500)); // Longer vibration duration
      HapticFeedback.vibrate(); // Trigger vibration again
      await Future.delayed(
          const Duration(milliseconds: 200)); // Shorter delay before next
    }
  }

  void _showNotificationDialog(
      BuildContext context, List<Map<String, dynamic>> notifications) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(child: Text('Aerosense Warning!')),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                for (var notification in notifications)
                  ListTile(
                    leading: Icon(Icons.circle, color: notification['color']),
                    title: Text(
                      notification['message'],
                      style: TextStyle(
                          fontSize: notification['fontSize'],
                          color: notification['color'],
                          fontFamily: 'handjet'),
                    ),
                  ),
                const Divider(),
                const Text(
                  'How to improve air quality:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                BulletList(
                  items: _getImprovementTips(notifications),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  List<String> _getImprovementTips(List<Map<String, dynamic>> notifications) {
    List<String> tips = [];

    for (var notification in notifications) {
      String message = notification['message'].toLowerCase();
      if (message.contains("sensitive levels")) {
        tips.addAll([
          'Ensure proper ventilation.',
          'Avoid smoking indoors.',
          'Use air purifiers if necessary.',
          'Minimize use of strong chemicals.',
          'Limit activities that generate dust.',
        ]);
      } else if (message.contains("hazardous")) {
        tips.addAll([
          'Stay indoors and keep all windows and doors closed.',
          'Use air purifiers with HEPA filters to clean the air.',
          'Avoid any activities that may stir up dust or pollutants.',
          'Wear masks if you need to move around in the area.',
          'Turn off air conditioning units that draw air from outside to prevent contamination.',
        ]);
      } else if (message.contains("unhealthy")) {
        tips.addAll([
          'Ensure proper ventilation by opening windows if safe to do so.',
          'Use air purifiers to help reduce indoor pollutants.',
          'Limit the use of candles and incense that can release harmful particles.',
          'Avoid using strong cleaning products or aerosols.',
          'Keep humidity levels in check to prevent mold growth.',
        ]);
      } else if (message.contains("harmful")) {
        tips.addAll([
          'Seal all entry points to prevent outside air from coming in.',
          'Use high-efficiency air purifiers to remove contaminants.',
          'Limit any cooking or heating that can release fumes or smoke.',
          'Use damp cloths for dusting to avoid stirring up particles.',
          'Stay informed about air quality updates and adjust indoor activities accordingly.',
        ]);
      }
    }

    // Remove duplicate tips
    return tips.toSet().toList();
  }
}

// BulletList widget to display a list with bullet points
class BulletList extends StatelessWidget {
  final List<String> items;

  const BulletList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text("• ", style: TextStyle(fontSize: 14)),
            Expanded(
              child: Text(item, style: const TextStyle(fontSize: 14)),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _PowerSwitchState extends State<PowerSwitch> {
  @override
  Widget build(BuildContext context) {
    final aqaProvider = Provider.of<AQAProvider>(context, listen: false);
    final temperatureProvider =
        Provider.of<Temperature>(context, listen: false);
    final humidityProvider = Provider.of<Humidity>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    aqaProvider.setContext(context);

    return GestureDetector(
      onTap: () {
        aqaProvider.togglePower();
        temperatureProvider.togglePower();
        humidityProvider.togglePower();
        notificationProvider.togglePower(); // Toggle notification fetching
      },
      child: Consumer<AQAProvider>(builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: provider.isPowerOn ? Colors.green : Colors.red,
          ),
          child: Icon(
            provider.isPowerOn ? Icons.power : Icons.power_off,
            color: Colors.white,
            size: 30,
          ),
        );
      }),
    );
  }
}
