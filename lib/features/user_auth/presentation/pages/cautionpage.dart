import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:aerosense_ph/features/user_auth/presentation/pages/monitorpage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HazardousMonitorPage extends StatefulWidget {
  @override
  _HazardousMonitorPageState createState() => _HazardousMonitorPageState();
}

class _HazardousMonitorPageState extends State<HazardousMonitorPage> {
  List<Map<String, String>> hazardousEvents = [];

  @override
  void initState() {
    super.initState();
    final monitor = HazardousEventMonitor();
    monitor.addListener(_onNewHazardousEvent);
    _loadHazardousEvents();
  }

  @override
  void dispose() {
    final monitor = HazardousEventMonitor();
    monitor.removeListener(_onNewHazardousEvent);
    super.dispose();
  }

  void _onNewHazardousEvent(Map<String, String> event) {
    setState(() {
      hazardousEvents.add(event);
    });
  }

  Future<void> _loadHazardousEvents() async {
    final monitor = HazardousEventMonitor();
    final filePath = await monitor.getFilePath(); // Use the public method
    File file = File(filePath);

    if (await file.exists()) {
      final contents = await file.readAsString();
      List<dynamic> events = jsonDecode(contents);

      setState(() {
        hazardousEvents = events
            .where((event) =>
                event['userId'] == FirebaseAuth.instance.currentUser?.uid)
            .map((e) => Map<String, String>.from(e))
            .toList();
      });
    }
  }

  Future<void> _clearHistory() async {
    final monitor = HazardousEventMonitor();
    final filePath = await monitor.getFilePath(); // Get the file path
    File file = File(filePath);

    if (await file.exists()) {
      await file.delete(); // Delete the file
    }

    setState(() {
      hazardousEvents.clear(); // Clear the list of events in the UI
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color.fromARGB(255, 18, 18, 19), // Set the background color
      appBar: AppBar(
        title: const Text(
          "Hazardous Events",
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'handjet',
              fontSize: 27,
              letterSpacing: 2.0),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              // Ask for confirmation before clearing history
              bool? confirmed = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Clear History"),
                  content: const Text(
                      "Are you sure you want to clear all hazardous events?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("Clear"),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                _clearHistory(); // Call the function to clear the history
              }
            },
          ),
        ],
      ),
      body: hazardousEvents.isEmpty
          ? const Center(
              child: Text("No hazardous events",
                  style: TextStyle(color: Colors.white)))
          : ListView.builder(
              itemCount: hazardousEvents.length,
              itemBuilder: (context, index) {
                final event = hazardousEvents[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: const Color.fromARGB(
                      255, 36, 36, 37), // Card background color
                  elevation: 4,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      event['message']!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${event['date']} at ${event['time']}\nLocation: ${event['lastLocation']}",
                      style: TextStyle(color: Colors.grey[300]),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
