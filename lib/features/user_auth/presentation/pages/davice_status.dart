import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DeviceStatusWidget extends StatefulWidget {
  final String blynkToken;

  const DeviceStatusWidget({
    Key? key,
    required this.blynkToken,
  }) : super(key: key);

  @override
  State<DeviceStatusWidget> createState() => _DeviceStatusWidgetState();
}

class _DeviceStatusWidgetState extends State<DeviceStatusWidget> {
  bool isDeviceOnline = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _checkDeviceStatus();
    // Set up the timer to fetch status every 3 seconds
    _timer = Timer.periodic(Duration(seconds: 2), (Timer t) {
      _checkDeviceStatus();
    });
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _timer.cancel();
    super.dispose();
  }

  Future<void> _checkDeviceStatus() async {
    final url =
        'http://blynk.cloud/external/api/isHardwareConnected?token=${widget.blynkToken}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          isDeviceOnline = json.decode(response.body) == true;
        });
      } else {
        setState(() {
          isDeviceOnline = false;
        });
      }
    } catch (e) {
      setState(() {
        isDeviceOnline = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(
      isDeviceOnline ? Icons.cloud_done : Icons.cloud_off,
      color: isDeviceOnline ? Colors.green : Colors.red,
      size: 21,
    );
  }
}
