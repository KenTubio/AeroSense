import 'package:aerosense_ph/features/user_auth/firebase_user_implementation/firebase_auth_services.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/forgot_pass.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/home_page.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/sensor_input_page.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/sensor_location_selection.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/signup_page.dart';
import 'package:aerosense_ph/features/user_auth/presentation/widgets/form_container_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isLoading = true;

  bool _isSigning = false;
  final FirebaseAuthService _auth = FirebaseAuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: -20.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Check if the user is already logged in
    _checkIfUserLoggedIn();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkIfUserLoggedIn() async {
    setState(() {
      _isLoading = true; // Show the loading indicator
    });

    bool isConnected = await _hasInternetConnection();

    if (!isConnected) {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      _showNoInternetDialog();
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('myUsers')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        if (!data.containsKey('sensorID')) {
          _navigateToSensorIDInput(user.uid);
        } else if (!data.containsKey('lastLocation')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SensorSelector()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    HomePage(selectedLocation: data['lastLocation'])),
          );
        }
      }
    }

    setState(() {
      _isLoading = false; // Hide loading indicator
    });
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      // Connection is successful if result is not empty and contains an address
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      // If an exception occurs, there is no internet connection
      return false;
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("No Internet Connection"),
          content: Text("Please check your internet connection and try again."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter your email and password.');
      setState(() {
        _isSigning = false;
      });
      return;
    }

    // Set signing state to true
    setState(() {
      _isSigning = true;
    });

    try {
      User? user = await _auth.signInWithEmailAndPassword(email, password);

      if (user != null) {
        setState(() {
          _isSigning = false;
        });

        print('User successfully logged in!');

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('myUsers')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;

          if (!data.containsKey('sensorID')) {
            _navigateToSensorIDInput(user.uid);
          } else if (!data.containsKey('lastLocation')) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SensorSelector()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      HomePage(selectedLocation: data['lastLocation'])),
            );
          }
        } else {
          _navigateToSensorIDInput(user.uid);
        }
      } else {
        setState(() {
          _isSigning = false;
        });
        _showErrorDialog('Login failed. Please check your email and password.');
      }
    } catch (e) {
      setState(() {
        _isSigning = false;
      });
      _showErrorDialog('An error occurred during login: ${e.toString()}');
    }
  }

  void _navigateToSensorIDInput(String uid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SensorIDInputPage(uid: uid),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.green,
          title: const Text(
            'Login Error',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'handjet',
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'handjet',
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'handjet',
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _animation.value),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/img/aerosense_logo.jpg',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome',
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'handjet',
                      letterSpacing: 4.0),
                ),
                const Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 20),
                FormContainerWidget(
                  controller: _emailController,
                  hintText: 'aerosense@gmail.com',
                  labelText: 'Email',
                  isPasswordField: false,
                ),
                const SizedBox(height: 20),
                FormContainerWidget(
                  controller: _passwordController,
                  hintText: '***************',
                  labelText: 'Password',
                  isPasswordField: true,
                ),
                const SizedBox(
                  height: 20,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ForgotPassword()),
                      );
                    },
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'handjet',
                          fontSize: 17,
                          letterSpacing: 2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: _login,
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: _isSigning
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'handjet',
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'handjet',
                        letterSpacing: 2.0,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignupPage()));
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'handjet',
                          letterSpacing: 2.0,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color:
                  Colors.black.withOpacity(0.7), // Semi-transparent background
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
