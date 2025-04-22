import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SensorIDInputPage extends StatefulWidget {
  final String uid;

  const SensorIDInputPage({super.key, required this.uid});

  @override
  _SensorIdInputPageState createState() => _SensorIdInputPageState();
}

class _SensorIdInputPageState extends State<SensorIDInputPage> {
  final TextEditingController _sensorIdController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _sensorIdController.dispose();
    super.dispose();
  }

  Future<bool> _isSensorIdInUse(String sensorId) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('myUsers')
        .where('sensorID', isEqualTo: sensorId)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<bool> _isValidSensorId(String sensorId) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('validSensorIDs')
        .where('sensorID', isEqualTo: sensorId)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> _submitSensorId() async {
    String sensorId = _sensorIdController.text.trim();
    if (sensorId.isEmpty) {
      _showErrorDialog("Please enter a valid Sensor ID.");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String currentUserId = widget.uid;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('myUsers')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>;

        if (data.containsKey('sensorID') && data['sensorID'] != null) {
          _showErrorDialog('This Sensor ID is already in use.');
          setState(() {
            _isSubmitting = false;
          });
          return;
        }

        if (!await _isValidSensorId(sensorId)) {
          _showErrorDialog("Invalid Sensor ID. Please enter a valid one.");
          setState(() {
            _isSubmitting = false;
          });
          return;
        }

        if (await _isSensorIdInUse(sensorId)) {
          _showErrorDialog('This Sensor ID is already in use by another user.');
          setState(() {
            _isSubmitting = false;
          });
          return;
        }

        await FirebaseFirestore.instance
            .collection('myUsers')
            .doc(currentUserId)
            .update({'sensorID': sensorId});

        if (data.containsKey('lastLocation')) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/sensorlocation');
        }
      }
    } catch (e) {
      _showErrorDialog("Error: ${e.toString()}");
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.green,
          title: const Text(
            'Error',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 19),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/img/man.jpg',
                  width: MediaQuery.of(context).size.width - 20,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _sensorIdController,
              decoration: const InputDecoration(
                labelText: 'Aerosense Sensor ID',
                labelStyle: TextStyle(color: Colors.white),
                hintText: 'Enter your sensor ID',
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'handjet',
                        letterSpacing: 2.0,
                      ),
                    ),
                    onPressed: _submitSensorId,
                    child: const Text("Submit Sensor ID"),
                  ),
          ],
        ),
      ),
    );
  }
}
