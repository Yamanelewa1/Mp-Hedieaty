import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSetupPage extends StatefulWidget {
  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String _selectedGender = 'Male';
  bool _isLoading = false;
  String? _profilePicturePath;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

// Validate email
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }


  // Validate phone number
  bool _isValidPhoneNumber(String phone) {
    final regex = RegExp(r'^\+?[1-9]\d{1,14}$');
    return regex.hasMatch(phone);
  }


  // Convert image to Base64 string
  Future<String> _convertImageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64String = base64Encode(imageBytes);
    return base64String;
  }

  // Save profile to Firestore
  Future<void> _saveProfile() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    if (!_isValidPhoneNumber(_phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid phone number.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      String? profilePictureBase64;
      if (_profilePicturePath != null) {
        // Convert image to Base64
        File imageFile = File(_profilePicturePath!);
        profilePictureBase64 = await _convertImageToBase64(imageFile);
      }

      // Create the full name by combining first name and last name
      final fullName = '${_firstNameController.text} ${_lastNameController.text}';

      // Save profile data to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'fullName': fullName, // Save combined full name
        'email': _emailController.text,
        'phoneNumber': _phoneController.text,
        'age': int.tryParse(_ageController.text) ?? 0,
        'gender': _selectedGender,
        'profilePicture': profilePictureBase64 ?? '', // Store the Base64 string
        'notificationsEnabled': true,
        'profileComplete': true, // Mark profile as complete
        'upcomingEvent': 0, // Default value for upcoming events
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile saved successfully!')),
      );

      // Navigate to home page
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile. Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Pick profile picture from gallery or camera
  Future<void> _pickProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Optional, reduce image size
    );

    if (pickedFile != null) {
      setState(() {
        _profilePicturePath = pickedFile.path;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Complete Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickProfilePicture,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profilePicturePath != null
                    ? FileImage(File(_profilePicturePath!))
                    : AssetImage('assets/images/default-avatar.png') as ImageProvider,
                child: _profilePicturePath == null
                    ? Icon(Icons.camera_alt, size: 30, color: Colors.grey)
                    : null,
              ),
            ),
            SizedBox(height: 20),
            // First Name Field
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            // Last Name Field
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            // Email Field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            // Phone Number Field
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            // Age Field
            TextField(
              controller: _ageController,
              decoration: InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
            ),
            // Gender Dropdown
            DropdownButton<String>(
              value: _selectedGender,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue!;
                });
              },
              items: _genderOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _saveProfile,
              child: Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
