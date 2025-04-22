import 'package:aerosense_ph/features/user_auth/firebase_user_implementation/firebase_auth_services.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/login.dart';
import 'package:aerosense_ph/features/user_auth/presentation/widgets/form_container_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isSigning = false; // Variable to track if signing up

  final FirebaseAuthService _auth = FirebaseAuthService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _locationController.dispose();
    _controller.dispose();
    super.dispose();
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
            const SizedBox(height: 10),
            const Text(
              'Create an Account!',
              style: TextStyle(
                fontSize: 30,
                color: Colors.white,
                letterSpacing: 2.0,
                fontFamily: 'handjet',
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Sign up to continue',
              style: TextStyle(
                fontSize: 9,
                color: Color.fromARGB(255, 178, 169, 169),
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 20),
            FormContainerWidget(
              controller: _usernameController,
              hintText: 'aerosense',
              isPasswordField: false,
              labelText: 'Username',
            ),
            const SizedBox(height: 20),
            FormContainerWidget(
              controller: _emailController,
              hintText: 'aerosense@gmail.com',
              isPasswordField: false,
              labelText: 'Email',
            ),
            const SizedBox(height: 20),
            FormContainerWidget(
              controller: _passwordController,
              hintText: '***************',
              isPasswordField: true,
              labelText: 'Password',
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _signUp,
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
                          'Signup',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'handjet',
                            fontWeight: FontWeight.bold,
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
                  "Already have an account?",
                  style: TextStyle(
                    color: Colors.white,
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
                      MaterialPageRoute(builder: (context) => const Login()),
                    );
                  },
                  child: const Text(
                    'Sign in',
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
    );
  }

  void _signUp() async {
    setState(() {
      _isSigning = true; // Start the loading indicator
    });

    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String location = _locationController.text.trim();

    String? errorMessage = _validateInputs(email, password);

    if (errorMessage != null) {
      setState(() {
        _isSigning = false; // Stop the loading indicator
      });
      _showErrorPopup(errorMessage);
      return; // Exit the function early
    }

    try {
      User? user =
          await _auth.signUpWithEmailAndPassword(email, password, username);
      setState(() {
        _isSigning = false; // Stop the loading indicator
      });

      // Show success popup only if user creation is successful
      if (user != null) {
        _showSuccessPopup('Account successfully created!');
        displayUsername(username, location);
      }
    } catch (e) {
      setState(() {
        _isSigning = false; // Stop the loading indicator
      });

      // Check if the error is due to an already existing email
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          _showErrorPopup(
              'The email address is already in use by another account.');
        } else {
          _showErrorPopup('An error occurred. Please try again later.');
        }
      } else {
        _showErrorPopup('An error occurred. Please try again later.');
      }
    }
  }

  Future<void> displayUsername(String username, String location) async {
    await FirebaseFirestore.instance.collection('myUsers').add({
      'username': username,
      'lastLocation': location,
    });
  }

  String? _validateInputs(String email, String password) {
    if (email.isEmpty) {
      return 'Email cannot be empty.';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      return 'Invalid email format.';
    }

    if (password.isEmpty) {
      return 'Password cannot be empty.';
    }
    if (password.length < 6) {
      return 'Password is too weak. It must be at least 6 characters.';
    }

    return null;
  }

  void _showSuccessPopup(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green,
          title: const Text(
            'Success',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'handjet',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'handjet',
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/login');
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'handjet',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red,
          title: const Text(
            'Error',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'handjet',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'handjet',
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'handjet',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
