import 'package:aerosense_ph/features/user_auth/presentation/pages/aqa_provider.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/back_button_handler.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/data_timer_service.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/davice_status.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/heat_index.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/history.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/weather_services.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/news_section.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/resources_section.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/gauge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  final String selectedLocation;

  HomePage({super.key, required this.selectedLocation});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String username = '';
  String sensorID = '';
  bool isLoading = true;
  String currentLocation = '';
  String? selectedLocation;
  int _currentIndex = 1;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final List<String> locations = [
    'Bedroom',
    'Office',
    'Living Room',
    'Kitchen',
    'Comfort Room',
  ];

  @override
  void initState() {
    super.initState();
    _getUsername();
    currentLocation = widget.selectedLocation;
    selectedLocation = currentLocation;
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final dataTimerService = Provider.of<DataTimerService>(context);
  }

  Future<void> _getUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('myUsers')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          username = userDoc['username'] ?? 'Guest';
          sensorID = userDoc['sensorID'];
          isLoading = false;
        });
      } else {
        setState(() {
          username = 'Guest';
          sensorID = 'guest';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        username = 'Guest';
        sensorID = 'guest';
        isLoading = false;
      });
    }
  }

  void _showUserPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 15, 40, 24),
          title: Center(
            child: Text(
              username.isNotEmpty ? username : 'Guest',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 40,
                letterSpacing: 2.0,
                fontFamily: 'handjet',
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Sensor ID:",
                  style: TextStyle(
                    color: Color.fromARGB(255, 156, 145, 145),
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.green,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text(
                      sensorID ?? 'No Sensor ID',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Center(
                child: Text(
                  "Edit Sensor Location:",
                  style: TextStyle(
                    color: Color.fromARGB(255, 156, 145, 145),
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.green,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: DropdownButton<String>(
                      value: selectedLocation ?? locations.first,
                      dropdownColor: const Color.fromARGB(255, 27, 81, 47),
                      style: const TextStyle(color: Colors.white),
                      underline: const SizedBox(),
                      items: locations.map((String location) {
                        return DropdownMenuItem<String>(
                          value: location,
                          child: Text(location),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedLocation = newValue;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () async {
                  if (selectedLocation != null) {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('myUsers')
                          .doc(user.uid)
                          .set({'lastLocation': selectedLocation},
                              SetOptions(merge: true));

                      setState(() {
                        currentLocation = selectedLocation!;
                      });
                    }
                  }
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "Save",
                  style: TextStyle(
                    color: Colors.white, // Text color
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),
            // More Options Button
            _buildActionButton(
              context,
              "More Options",
              const Color.fromARGB(255, 75, 56, 153),
              () {
                Navigator.of(context).pop();
                _showMoreOptionsPopup(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showMoreOptionsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 15, 40, 24),
          title: const Text(
            "More Options",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            _buildActionButton(
              context,
              "Cancel",
              Colors.blue,
              () {
                Navigator.of(context).pop();
              },
            ),
            _buildActionButton(
              context,
              "Delete Sensor ID",
              Colors.red,
              () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: const Color.fromARGB(255, 18, 18, 19),
                      title: const Text(
                        "Are you sure?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const Text(
                        "You are about to delete your Sensor ID and log out.",
                        style: TextStyle(color: Colors.white),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              await FirebaseFirestore.instance
                                  .collection('myUsers')
                                  .doc(user.uid)
                                  .update({'sensorID': FieldValue.delete()});
                              await FirebaseAuth.instance.signOut();
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                          child: const Text(
                            "Delete Sensor ID",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            _buildActionButton(
              context,
              "Sign Out",
              Colors.red,
              () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(
      BuildContext context, String label, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: color,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(color: color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => BackButtonHandler.handleBackButton(context),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 18, 18, 19),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        _buildHeader(),
                        Expanded(
                          child: _buildContent(),
                        ),
                      ],
                    ),
            ),
            if (_currentIndex == 1)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  color: const Color.fromARGB(255, 62, 62, 60),
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      Expanded(
                        child: Consumer<Temperature>(
                          builder: (context, temperatureProvider, _) {
                            return _buildInfoBox(
                              icon: Icons.thermostat,
                              label: 'Temperature',
                              value: '${temperatureProvider.temperature}°C',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Consumer<Humidity>(
                          builder: (context, humidityProvider, _) {
                            return _buildInfoBox(
                              icon: Icons.water_drop,
                              label: 'Humidity',
                              value: '${humidityProvider.humidity}%',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          child: _buildBottomNavigationBar(),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_currentIndex == 0 ||
        _currentIndex == 3 ||
        _currentIndex == 2 ||
        _currentIndex == 4) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      currentLocation,
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 5.0,
                        fontFamily: 'handjet',
                      ),
                    ),
                    const SizedBox(width: 10),
                    const DeviceStatusWidget(
                        blynkToken:
                            'Cc4I-8AMONW2CZwWkd-bZEz10otAcMOw'), // Call the widget here
                  ],
                ),
                const Text(
                  'Air Quality Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color.fromARGB(255, 157, 154, 154),
                    letterSpacing: 1.0,
                    fontFamily: 'handjet',
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showUserPopup(context),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                    width: 50,
                    height: 50,
                    child: Center(
                      child: Text(
                        username.isNotEmpty ? username[0].toUpperCase() : 'G',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'handjet',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BellIcon(),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: notificationProvider.notifications
                            .map((notification) {
                          return ListTile(
                            title: Text(
                              notification['message'],
                              style: TextStyle(
                                color: notification['color'],
                                fontFamily: 'handjet',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                fontSize: notification['fontSize'],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildInfoBox(
      {required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(35.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 18, 18, 19),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentIndex) {
      case 0:
        return const NewsSection();
      case 1:
        return Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.20),
            Expanded(
              child: Consumer<AQAProvider>(
                builder: (context, aqaProvider, _) {
                  aqaProvider.setContext(context);

                  return Column(
                    children: [
                      GaugeWidget(
                        needleValue: aqaProvider.needleValue,
                      ),
                      const SizedBox(height: 60),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center, // Center the row content
                        children: [
                          const PowerSwitch(),
                          const SizedBox(
                              width:
                                  10), // Add space between the switch and the icon
                          GestureDetector(
                              onTap: () {
                                // Navigate to the other page when the icon is clicked
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => HeatIndex()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors
                                      .green, // You can change the color dynamically here
                                ),
                                child: Icon(
                                  Icons.wb_sunny, // Icon to click
                                  size: 30, // Icon size
                                  color: Colors.white, // Icon color
                                ),
                              )),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      case 2:
        return const ResourcesSection();
      case 3:
        return const WeatherSection();
      case 4:
        return const DailyAverageChartScreen();
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      color: const Color.fromARGB(255, 26, 25, 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(
            icon: Icons.article,
            label: 'Headlines',
            index: 0,
          ),
          _buildBottomNavItem(
            icon: Icons.bar_chart,
            label: 'History',
            index: 4,
          ),
          _buildBottomNavItem(
            icon: Icons.sensors,
            label: 'Aerosense.',
            index: 1,
          ),
          _buildBottomNavItem(
            icon: Icons.thermostat,
            label: 'AQA Scale',
            index: 2,
          ),
          _buildBottomNavItem(
            icon: Icons.filter_drama,
            label: 'Weather',
            index: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.green : Colors.white,
            size: isSelected ? 30 : 22,
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'handjet',
              color: isSelected ? Colors.green : Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
