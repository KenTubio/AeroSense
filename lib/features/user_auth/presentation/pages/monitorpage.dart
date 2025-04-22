import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HazardousEventMonitor {
  final String blynkToken = "Cc4I-8AMONW2CZwWkd-bZEz10otAcMOw";
  final String pin = "V2";
  Timer? _timer;
  final List<Function(Map<String, String>)> _listeners = [];

  // Singleton instance
  static final HazardousEventMonitor _instance =
      HazardousEventMonitor._internal();

  factory HazardousEventMonitor() {
    return _instance;
  }

  HazardousEventMonitor._internal();

  void startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchAndMonitorHazardous();
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
  }

  void addListener(Function(Map<String, String>) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(Map<String, String>) listener) {
    _listeners.remove(listener);
  }

  // Public method to get file path
  Future<String> getFilePath() async {
    final directory =
        Directory.systemTemp; // Temporary directory for file storage
    final user = FirebaseAuth.instance.currentUser;
    return '${directory.path}/hazardous_events_${user?.uid}.json';
  }

  Future<void> _fetchAndMonitorHazardous() async {
    final url = Uri.parse(
        "http://blynk.cloud/external/api/get?token=$blynkToken&pin=$pin");

    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(url);
      final response = await request.close();

      if (response.statusCode == 200) {
        final value = await response.transform(utf8.decoder).join();

        if (value.contains("Hazardous") || value.contains("Harmful")) {
          final currentTime = DateTime.now();
          final date =
              "${currentTime.year}-${currentTime.month.toString().padLeft(2, '0')}-${currentTime.day.toString().padLeft(2, '0')}";
          final time = "${currentTime.hour}:${currentTime.minute}";

          String message =
              value.contains("Hazardous") ? "Hazardous" : "Harmful";

          final user = FirebaseAuth.instance.currentUser;
          String lastLocation = 'Unknown';

          if (user != null) {
            final userDoc = await FirebaseFirestore.instance
                .collection('myUsers')
                .doc(user.uid)
                .get();

            if (userDoc.exists) {
              lastLocation = userDoc['lastLocation'] ?? 'Unknown';
            }
          }

          final newEvent = {
            "message": message,
            "date": date,
            "time": time,
            "lastLocation": lastLocation,
            "userId": user?.uid ?? "",
          };

          // Save to file
          await _saveHazardousEventToFile(newEvent);

          // Notify listeners
          for (var listener in _listeners) {
            listener(newEvent);
          }
        }
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  Future<void> _saveHazardousEventToFile(Map<String, String> event) async {
    final filePath = await getFilePath();
    File file = File(filePath);

    try {
      if (await file.exists()) {
        final contents = await file.readAsString();
        List<dynamic> events = jsonDecode(contents);
        events.add(event);
        await file.writeAsString(jsonEncode(events));
      } else {
        List<dynamic> events = [event];
        await file.writeAsString(jsonEncode(events));
      }
    } catch (e) {
      print("Error saving hazardous event to file: $e");
    }
  }
}
