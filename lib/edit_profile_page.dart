import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _profilePictureUrl = '';
  XFile? _imageFile;
  bool _isLoading = false;
  String _selectedGender = '';

  // Fetch user profile details
  Future<void> _fetchUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(user.uid).get();
      if (snapshot.exists) {
        var userData = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _ageController.text = userData['age'] ?? '';
          _selectedGender = userData['gender'] ?? '';
          _phoneController.text = userData['phoneNumber'] ?? '';
          _profilePictureUrl = userData['profilePicture'] ?? '';
        });
      }
    }
  }

  // Update user profile details
  Future<void> _updateProfile() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        String firstName = _firstNameController.text.trim();
        String lastName = _lastNameController.text.trim();
        String email = _emailController.text.trim();
        String age = _ageController.text.trim();
        String phoneNumber = _phoneController.text.trim();

        if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || age.isEmpty || _selectedGender.isEmpty || phoneNumber.isEmpty) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('All fields are required!')));
          return;
        }

        String? profilePictureUrl = _profilePictureUrl;

        if (_imageFile != null) {
          profilePictureUrl = await _uploadProfilePicture();
        }

        await user.updateEmail(email);
        await _firestore.collection('users').doc(user.uid).update({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'age': age,
          'gender': _selectedGender,
          'phoneNumber': phoneNumber,
          'profilePicture': profilePictureUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully!')));
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile!')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Upload profile picture to Firebase Storage
  Future<String> _uploadProfilePicture() async {
    if (_imageFile == null) return '';

    try {
      String fileName = 'profile_pictures/${_auth.currentUser!.uid}.jpg';
      Reference storageRef = _storage.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(File(_imageFile!.path));
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return '';
    }
  }

  // Pick image from gallery or camera
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.blueAccent,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _updateProfile,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _imageFile == null
                      ? (_profilePictureUrl.isNotEmpty
                      ? NetworkImage(_profilePictureUrl)
                      : AssetImage('assets/images/default-avatar.png') as ImageProvider)
                      : FileImage(File(_imageFile!.path)) as ImageProvider,
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildTextField('First Name', _firstNameController),
            SizedBox(height: 12),
            _buildTextField('Last Name', _lastNameController),
            SizedBox(height: 12),
            _buildTextField('Email', _emailController, keyboardType: TextInputType.emailAddress),
            SizedBox(height: 12),
            _buildTextField('Age', _ageController, keyboardType: TextInputType.number),
            SizedBox(height: 12),
            _buildGenderDropdown(),
            SizedBox(height: 12),
            _buildTextField('Phone Number', _phoneController, keyboardType: TextInputType.phone),
            SizedBox(height: 20),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
      keyboardType: keyboardType,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender.isNotEmpty ? _selectedGender : null,
      decoration: InputDecoration(
        labelText: 'Gender',
        labelStyle: TextStyle(color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: ['Male', 'Female', 'Other']
          .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedGender = value ?? '';
        });
      },
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _updateProfile,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: Colors.blueAccent, // Correct parameter
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: _isLoading
          ? CircularProgressIndicator(color: Colors.white)
          : Text('Save Changes', style: TextStyle(color: Colors.white)),
    );
  }
}
