import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _retypePasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  final _formKey = GlobalKey<FormState>(); // Added form key for validation
  bool _isLoading = false; // Loading state

  // Function to handle Sign Up
  Future<void> _signUp() async {
    if (_passwordController.text != _retypePasswordController.text) {
      _showErrorDialog('Passwords do not match. Please try again.');
      return;
    }

    setState(() {
      _isLoading = true; // Show loading spinner
    });

    try {
      // Create a new user with Firebase Authentication
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // After successful registration, save user data to Firebase Realtime Database
      final user = userCredential.user;
      if (user != null) {
        String uid = user.uid;
        // Store additional user information (for example: username, email, etc.) in Realtime Database
        await _database.ref('users/$uid').set({
          'email': user.email,
          'username': 'default_username',  // Default value or allow user to update later
          'createdAt': DateTime.now().toString(),
        });
      }

      // After saving user data, navigate back to login page
      Navigator.pop(context); // Pop the current sign-up page and go back to the login page
    } on FirebaseAuthException catch (e) {
      // Specific FirebaseAuth errors
      _showErrorDialog(e.message ?? 'An error occurred during sign-up');
    } catch (e) {
      // General errors
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false; // Hide loading spinner
      });
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // Password strength validator
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Subtle background color
      appBar: AppBar(
        title: Text('Sign Up'),
        backgroundColor: Colors.blue, // Blue app bar
      ),
      body: SafeArea(
        child: SingleChildScrollView( // Wrap the content in SingleChildScrollView for better handling of small screens
          padding: const EdgeInsets.all(16.0),
          child: Form(  // Wrap the fields in a Form widget
            key: _formKey,  // Associate the form with the form key
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Larger logo at the top (adjusted size)
                Center(
                  child: Image.asset(
                    'assets/images/app_logo.gif', // Add your logo path here
                    width: 200, // Increased size
                    height: 200, // Increased size
                  ),
                ),
                const SizedBox(height: 40), // Reduced space below the logo

                // Welcome text
                Text(
                  'Create Your Account',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),

                // Email Text Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.deepPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.email, color: Colors.deepPurple),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20), // Spacing between text fields

                // Password Text Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.deepPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.lock, color: Colors.deepPurple),
                  ),
                  obscureText: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 20), // Spacing between text fields

                // Retype Password Text Field
                TextFormField(
                  controller: _retypePasswordController,
                  decoration: InputDecoration(
                    labelText: 'Retype Password',
                    labelStyle: TextStyle(color: Colors.deepPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.lock, color: Colors.deepPurple),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please re-enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20), // Spacing between text fields

                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null // Disable the button when loading
                      : () {
                    // Perform validation and then sign up
                    if (_formKey.currentState?.validate() ?? false) {
                      _signUp();
                    }
                  },
                  child: _isLoading
                      ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Set button background color to blue
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30), // Padding for the button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Rounded edges
                    ),
                    elevation: 5, // Added shadow for the button
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Text style with white color
                  ),
                ),
                const SizedBox(height: 20), // Spacing between buttons

                // Sign-in Redirect Button
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to login page
                  },
                  child: Text(
                    'Already have an account? Sign In',
                    style: TextStyle(color: Colors.deepPurple, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
