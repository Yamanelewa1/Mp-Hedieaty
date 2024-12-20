import 'package:sqflite/sqflite.dart';

class User {
  String id;
  int age;
  String email;
  String fullName;
  String gender;
  bool notificationsEnabled;
  String phoneNumber;
  bool profileComplete;
  String profilePicture;
  int upcomingEvent;

  User({
    required this.id,
    required this.age,
    required this.email,
    required this.fullName,
    required this.gender,
    required this.notificationsEnabled,
    required this.phoneNumber,
    required this.profileComplete,
    required this.profilePicture,
    required this.upcomingEvent,
  });

  // Convert a User object to a map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'age': age,
      'email': email,
      'fullName': fullName,
      'gender': gender,
      'notificationsEnabled': notificationsEnabled ? 1 : 0,
      'phoneNumber': phoneNumber,
      'profileComplete': profileComplete ? 1 : 0,
      'profilePicture': profilePicture,
      'upcomingEvent': upcomingEvent,
    };
  }

  // Create a User object from a map returned by SQLite
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      age: map['age'],
      email: map['email'],
      fullName: map['fullName'],
      gender: map['gender'],
      notificationsEnabled: map['notificationsEnabled'] == 1,
      phoneNumber: map['phoneNumber'],
      profileComplete: map['profileComplete'] == 1,
      profilePicture: map['profilePicture'],
      upcomingEvent: map['upcomingEvent'],
    );
  }
}

