import 'package:sqflite/sqflite.dart';

class Friend {
  String userId; // ID of the user
  String friendId; // ID of the friend

  Friend({required this.userId, required this.friendId});

  // SQLite table creation
  static const String tableName = 'friends';

  static const String createTableQuery = '''
    CREATE TABLE $tableName (
      userId TEXT NOT NULL,
      friendId TEXT NOT NULL,
      PRIMARY KEY (userId, friendId)
    );
  ''';

  // Convert Friend object to Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'friendId': friendId,
    };
  }

  // Create Friend object from Map
  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      userId: map['userId'] as String,
      friendId: map['friendId'] as String,
    );
  }
}
