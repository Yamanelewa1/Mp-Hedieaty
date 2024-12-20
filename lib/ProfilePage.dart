import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'edit_profile_page.dart';
import 'pledgedgiftspage.dart';
import 'eventlistpage.dart';

class ProfilePage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> _getUserProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await _firestore.collection('users').doc(user.uid).get();
        return snapshot.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Error loading profile.'));
          }

          Map<String, dynamic> userData = snapshot.data!;

          String profilePictureBase64 = userData['profilePicture'] ?? '';
          Uint8List? profilePictureBytes;
          if (profilePictureBase64.isNotEmpty) {
            profilePictureBytes = base64Decode(profilePictureBase64);
          }

          String fullName = userData['fullName'] ?? 'No Full Name';
          String email = userData['email'] ?? 'No Email';
          String phoneNumber = userData['phoneNumber'] ?? 'Not Provided';
          String age = (userData['age'] ?? 'Not Provided').toString();
          String gender = userData['gender'] ?? 'Not Provided';
          bool notificationsEnabled = userData['notificationsEnabled'] ?? true;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.indigo.shade300, Colors.indigo.shade900],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: <Widget>[
                Center(
                  child: CircleAvatar(
                    radius: 70,
                    backgroundImage: profilePictureBytes != null
                        ? MemoryImage(profilePictureBytes)
                        : AssetImage('assets/images/default-avatar.png')
                    as ImageProvider,
                    backgroundColor: Colors.grey[300],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 20),
                Divider(color: Colors.white70, thickness: 0.5),
                ListTile(
                  leading: Icon(Icons.phone, color: Colors.white),
                  title: Text('Phone Number', style: TextStyle(color: Colors.white)),
                  subtitle: Text(phoneNumber, style: TextStyle(color: Colors.white70)),
                ),
                ListTile(
                  leading: Icon(Icons.cake, color: Colors.white),
                  title: Text('Age', style: TextStyle(color: Colors.white)),
                  subtitle: Text(age, style: TextStyle(color: Colors.white70)),
                ),
                ListTile(
                  leading: Icon(Icons.person, color: Colors.white),
                  title: Text('Gender', style: TextStyle(color: Colors.white)),
                  subtitle: Text(gender, style: TextStyle(color: Colors.white70)),
                ),
                SwitchListTile(
                  activeColor: Colors.tealAccent,
                  inactiveThumbColor: Colors.grey,
                  title: Text('Enable Notifications', style: TextStyle(color: Colors.white)),
                  value: notificationsEnabled,
                  onChanged: (value) {
                    _firestore
                        .collection('users')
                        .doc(_auth.currentUser?.uid)
                        .update({'notificationsEnabled': value});
                  },
                ),
                Divider(color: Colors.white70, thickness: 0.5, height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfilePage()),
                    );
                  },
                  child: Text('Edit Profile', style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyPledgedGiftsPage()),
                    );
                  },
                  child: Text('View Pledged Gifts', style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EventListPage()),
                    );
                  },
                  child: Text('View Event List', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
