import 'package:aerosense_ph/features/user_auth/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SensorSelector extends StatefulWidget {
  const SensorSelector({super.key});

  @override
  _SensorLocationSelectionState createState() =>
      _SensorLocationSelectionState();
}

class _SensorLocationSelectionState extends State<SensorSelector> {
  bool isLoading = false;

  void _navigateToHomePage(String location) async {
    setState(() {
      isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance.collection('myUsers').doc(user.uid).set({
        'lastLocation': location,
      }, SetOptions(merge: true));
    }

    await Future.delayed(const Duration(seconds: 2));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(selectedLocation: location),
      ),
    );

    setState(() {
      isLoading = false; // Stop loading
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 19),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 40, bottom: 20),
              child: Text(
                "Choose Sensor Location",
                style: TextStyle(
                  fontFamily: 'handjet',
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildImageLocationBox(
                              "Bedroom", 'assets/img/bedroom.jpg'),
                          const SizedBox(height: 20),
                          _buildImageLocationBox(
                              "Living Room", 'assets/img/livingroom.jpg'),
                          const SizedBox(height: 20),
                          _buildImageLocationBox(
                              "Kitchen", 'assets/img/kitchen.jpg'),
                          const SizedBox(height: 20),
                          _buildImageLocationBox(
                              "Comfort Room", 'assets/img/bathtub.jpg'),
                          const SizedBox(height: 20),
                          _buildImageLocationBox(
                              "Office", 'assets/img/office.jpg'),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageLocationBox(String location, String imagePath) {
    return Center(
      child: GestureDetector(
        onTap: () => _navigateToHomePage(location),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color:
                    const Color.fromARGB(255, 222, 211, 211).withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  imagePath,
                  width: 200,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                location,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'handjet',
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
