import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'UsersTable.dart'; // Import your User class
import 'Friend.dart'; // Import your Friend class
import 'Event.dart'; // Import your Event class
import 'Gift.dart'; // Import your Gift class

// Define the users table creation query
const String createUsersTableQuery = '''
  CREATE TABLE users (
    id TEXT PRIMARY KEY,
    age INTEGER,
    email TEXT,
    fullName TEXT,
    gender TEXT,
    notificationsEnabled INTEGER,
    phoneNumber TEXT,
    profileComplete INTEGER,
    profilePicture TEXT,
    upcomingEvent INTEGER
  );
''';

// Define the friends table creation query
const String createFriendsTableQuery = '''
  CREATE TABLE friends (
    userId TEXT NOT NULL,
    friendId TEXT NOT NULL,
    PRIMARY KEY (userId, friendId)
  );
''';

// Define the events table creation query
const String createEventsTableQuery = '''
  CREATE TABLE events (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    date TEXT NOT NULL,
    createdAt TEXT NOT NULL,
    creatorId TEXT NOT NULL,
    FOREIGN KEY (creatorId) REFERENCES users (id) ON DELETE CASCADE
  );
''';

// Define the gifts table creation query
const String createGiftsTableQuery = '''
  CREATE TABLE gifts (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    price REAL,
    status TEXT,
    image TEXT,
    eventId TEXT NOT NULL,
    FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
  );
''';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'app_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(createUsersTableQuery);
        await db.execute(createFriendsTableQuery);
        await db.execute(createEventsTableQuery);
        await db.execute(createGiftsTableQuery);
      },
    );
  }

  // Users table methods
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<int> updateUser(String userId, Map<String, dynamic> user) async {
    final db = await database;
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteUser(String userId) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Gift table methods
  Future<int> insertGift(Gift gift) async {
    final db = await database;
    return await db.insert(
      'gifts',
      gift.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Gift>> getGiftsByEventId(String eventId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'gifts',
      where: 'eventId = ?',
      whereArgs: [eventId],
    );

    return List.generate(maps.length, (i) {
      return Gift.fromMap(maps[i]);
    });
  }

  Future<int> updateGift(Gift gift) async {
    final db = await database;
    return await db.update(
      'gifts',
      gift.toMap(),
      where: 'id = ?',
      whereArgs: [gift.id],
    );
  }

  Future<int> deleteGift(String giftId) async {
    final db = await database;
    return await db.delete(
      'gifts',
      where: 'id = ?',
      whereArgs: [giftId],
    );
  }

  Future<int> deleteAllGiftsByEventId(String eventId) async {
    final db = await database;
    return await db.delete(
      'gifts',
      where: 'eventId = ?',
      whereArgs: [eventId],
    );
  }
}
