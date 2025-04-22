import 'package:aerosense_ph/features/user_auth/firebase_user_implementation/firebase_auth_services.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/forgot_pass.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/home_page.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/sensor_location_selection.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/signup_page.dart';
import 'package:aerosense_ph/features/user_auth/presentation/widgets/form_container_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Login method with enhanced error handling
  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Check if email and password are not empty
    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Login Error', 'Please enter your email and password.',
          showCreateAccount: false);
      return;
    }

    // Validate email format
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showErrorDialog('Login Error', 'Please enter a valid email address.',
          showCreateAccount: false);
      return;
    }

    setState(() {
      _isSigning = true; // Show loading spinner
    });

    try {
      // Try to sign in with email and password
      User? user = await _auth.signInWithEmailAndPassword(email, password);

      if (user != null) {
        // If login is successful, check Firestore for the saved location
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('myUsers')
            .doc(user.uid)
            .get();

        setState(() {
          _isSigning = false; // Hide loading spinner
        });

        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;

          // Check if 'lastLocation' exists in Firestore
          if (data.containsKey('lastLocation')) {
            String savedLocation = data['lastLocation'];
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      HomePage(selectedLocation: savedLocation)),
            );
          } else {
            // If no saved location, navigate to the sensor selector page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SensorSelector()),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      // This part handles authentication errors
      setState(() {
        _isSigning = false; // Hide loading spinner
      });

      switch (e.code) {
        case 'user-not-found':
          _showErrorDialog('Login Error',
              'Account does not exist. Please create an account.',
              showCreateAccount: true);
          break;
        case 'wrong-password':
          _showErrorDialog(
              'Login Error', 'Incorrect password. Please try again.',
              showCreateAccount: false);
          break;
        case 'invalid-email':
          _showErrorDialog('Login Error',
              'Invalid email format. Please enter a valid email.',
              showCreateAccount: false);
          break;
        case 'user-disabled':
          _showErrorDialog('Login Error',
              'This account has been disabled. Please contact support.',
              showCreateAccount: false);
          break;
        case 'too-many-requests':
          _showErrorDialog(
              'Login Error', 'Too many login attempts. Try again later.',
              showCreateAccount: false);
          break;
        case 'invalid-credential':
          _showErrorDialog(
              'Login Error', 'Invalid credentials. Please try again.',
              showCreateAccount: false);
          break;
        default:
          _showErrorDialog(
              'Login Error', 'Login failed. Please check your credentials.',
              showCreateAccount: false);
      }
    } catch (e) {
      // Handle other types of errors (like network issues)
      setState(() {
        _isSigning = false; // Hide loading spinner
      });
      _showErrorDialog('Login Error', 'An error occurred. Please try again.',
          showCreateAccount: false);
    }
  }

  // Show error dialog with red background and optional create account button
  void _showErrorDialog(String title, String message,
      {bool showCreateAccount = false}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.red, // Set background to red
          title: Text(
            title,
            style: const TextStyle(
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
            if (showCreateAccount)
              TextButton(
                child: const Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'handjet',
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SignupPage()),
                  );
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
      body: Padding(
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
              'Welcome..',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'handjet',
              ),
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
                    color: Color.fromARGB(255, 173, 173, 173),
                    fontFamily: 'handjet',
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignupPage()),
                    );
                  },
                  child: const Text(
                    'Sign up',
                    style: TextStyle(
                      color: Colors.green,
                      fontFamily: 'handjet',
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
