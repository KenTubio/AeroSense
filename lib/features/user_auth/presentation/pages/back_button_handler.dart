import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class BackButtonHandler {
  static DateTime? _lastPressedTime;

  static Future<bool> handleBackButton(BuildContext context) async {
    final now = DateTime.now();
    const backPressDuration = Duration(seconds: 2);

    // Check if back button is pressed within 2 seconds
    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > backPressDuration) {
      _lastPressedTime = now;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Press back again to logout"),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return false;
    }

    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    // After sign out, navigate to the login screen
    Navigator.pushReplacementNamed(context, '/login');
    return true;
  }
}
